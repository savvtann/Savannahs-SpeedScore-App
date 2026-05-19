using Toybox.Communications;
using Toybox.System;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Application.Properties;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Position;

class APIClient {
    var token        = null;
    var userID       = null;
    var refreshToken = null;
    var deviceId     = null;
    var pairingCode  = null;
    var _pairingView = null;
    var _pendingLat               = 0.0;
    var _pendingLng               = 0.0;
    var _nearestCourseCallback    = null;
    var _lastSearchQuery          = null;
    var baseUrl      = "https://api.speedscore.org";
    public var _AudioHelper;
    hidden var _pendingRoundState    = null;
    hidden var _pendingRoundCallback = null;

    function initialize() {
        token        = Properties.getValue("authToken");
        userID       = Properties.getValue("userID");
        refreshToken = Properties.getValue("refreshToken");
        deviceId     = Properties.getValue("deviceId");

        // Seed device ID from hardware the first time (or if the stored value was cleared)
        if (deviceId == null || deviceId.equals("") || deviceId.equals("null")) {
            var settings = System.getDeviceSettings();
            if (settings != null && settings.uniqueIdentifier != null) {
                deviceId = settings.uniqueIdentifier.toString();
                Properties.setValue("deviceId", deviceId);
                System.println("Device ID seeded from hardware: " + deviceId);
            }
        }

        System.println("APIClient created — deviceId=" + deviceId);
        _AudioHelper = new AudioHelper();
    }

    // ── RESPONSE HANDLERS ────────────────────────────────────

    function onReceive(responseCode, data) {
        System.println("Response code: " + responseCode);
        System.println("Data: " + data);
        if (responseCode == 200) {
            System.println("Request Successful");
        } else {
            System.println("Error: " + responseCode);
        }
    }

    // Saves just the JWT — used by loginLight and loginDevice
    // These endpoints only return { "jwtToken": "..." }
    function handleJwtResponse(data) {
        token = data["jwtToken"];
        Properties.setValue("authToken", token);
        System.println("JWT saved");
        if (userID == null || userID.equals("") || userID.equals("null")) {
            fetchUserProfile();
        }
    }

    // Saves full credentials — used by original login() only
    // That endpoint returns jwtToken + user._id + refreshToken
    function handleLoginSuccess(data) {
        token        = data["jwtToken"];
        userID       = data["user"]["_id"];
        refreshToken = data["refreshToken"];
        Properties.setValue("authToken", token);
        Properties.setValue("userID", userID);
        Properties.setValue("refreshToken", refreshToken);
        System.println("Full login successful, credentials saved");
    }

    // Original /auth/login response
    function onLoginResponse(responseCode, data) {
        if (responseCode == 200 && data instanceof Dictionary) {
            handleLoginSuccess(data);
        } else {
            System.println("Login failed: " + responseCode + "\nError: " + data);
        }
    }

    // POST /users/garmin/login/light response
    // Returns: { "jwtToken": "..." } only
    function onLoginLightResponse(responseCode, data) {
        if (responseCode == 200 && data instanceof Dictionary) {
            handleJwtResponse(data);
        } else {
            System.println("Light login failed: " + responseCode + "\nError: " + data);
            System.println("Falling back to standard login...");
            login();
        }
    }

    function fetchUserProfile() {
        // Decode userID from JWT token — it's in the payload
        // JWT format: header.payload.signature — payload is base64 encoded JSON
        // For now just call getUsers with a /me endpoint if available,
        // or fall back to standard login which returns the full profile
        System.println("Fetching user profile for userID...");
        var url = baseUrl + "/users/me";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(url, {}, options, method(:onUserProfileResponse));
    }

    function onUserProfileResponse(responseCode, data) {
        if (responseCode == 200 && data instanceof Dictionary) {
            userID = data["_id"];
            Properties.setValue("userID", userID);
            System.println("UserID fetched: " + userID);
        } else {
            System.println("User profile fetch failed: " + responseCode + " — falling back to standard login");
            login();
        }
    }

    // POST /users/garmin/login/device response
    // Returns: { "jwtToken": "..." } only
    // 404 means device not linked yet — start pairing flow
    function onLoginDeviceResponse(responseCode, data) {
        if (responseCode == 200 && data instanceof Dictionary) {
            handleJwtResponse(data);
        } else if (responseCode == 404) {
            // No account linked to this device — show pairing screen
            System.println("Device not linked — starting pairing flow");
            initiatePairing();
        } else {
            System.println("Device login failed: " + responseCode + "\nError: " + data);
            System.println("Falling back to light login...");
            loginLight();
        }
    }

    // POST /users/garmin/pairing/initiate response
    // Returns: { "pairingCode": "K7M2P9", "expiresAt": "..." }
    function onPairingInitiateResponse(responseCode, data) {
        if (responseCode == 200 && data instanceof Dictionary) {
            pairingCode = data["pairingCode"];
            Properties.setValue("pairingCode", pairingCode);
            System.println("Pairing initiated — code: " + pairingCode);
            if (_pairingView == null) {
                _pairingView = new PairingView(pairingCode);
                WatchUi.pushView(_pairingView, new PairingDelegate(_pairingView, false), WatchUi.SLIDE_UP);
            } else {
                _pairingView.setCode(pairingCode);
                WatchUi.requestUpdate();
            }
        } else {
            System.println("Pairing initiate failed: " + responseCode + "\nError: " + data);
        }
    }

    function clearPairingView() {
        _pairingView = null;
    }

    // POST /users/garmin/pairing/complete response
    // Returns: { "success": true, "garminDeviceId": "..." }
    // 404 = code not found/expired, 409 = code already used by another account
    function onCompletePairingResponse(responseCode, data) {
        if (responseCode == 200 && data instanceof Dictionary) {
            System.println("Pairing complete — device linked: " + data["garminDeviceId"]);
            loginDevice();
        } else if (responseCode == 404) {
            System.println("Pairing code not found or expired — reinitialising");
            initiatePairing();
        } else if (responseCode == 409) {
            System.println("Pairing code already used by a different account");
        } else if (responseCode == 401) {
            System.println("Not authenticated — cannot complete pairing from watch");
        } else {
            System.println("Complete pairing failed: " + responseCode);
        }
    }

    // GET /users/garmin/pairing/status response
    // Returns: { "status": "pending" | "linked" | "expired" }
    function onPairingStatusResponse(responseCode, data) {
        if (responseCode == 200 && data instanceof Dictionary) {
            var status = data["status"];
            System.println("Pairing status: " + status);
            if (status.equals("linked")) {
                // User has completed pairing on the web app
                // Now authenticate using device ID
                System.println("Pairing linked — logging in with device ID");
                loginDevice();
            } else if (status.equals("expired")) {
                // Code expired — request a fresh one
                System.println("Pairing code expired — reinitialising");
                initiatePairing();
            }
            // "pending" = keep polling, nothing to do
        } else {
            System.println("Pairing status check failed: " + responseCode);
        }
    }

    // GET /users/garmin/link-status response
    // Returns: { "linked": true, "garminDeviceId": "...", "linkedAt": "..." }
    function onLinkStatusResponse(responseCode, data) {
        if (responseCode == 200 && data instanceof Dictionary) {
            var linked = data["linked"];
            System.println("Watch linked: " + linked);
            if (linked) {
                System.println("Device ID: " + data["garminDeviceId"]);
                System.println("Linked at: " + data["linkedAt"]);
            }
        } else {
            System.println("Link status failed: " + responseCode);
        }
    }

    // DELETE /users/garmin/link response
    // Returns: { "success": true }
    function onUnlinkResponse(responseCode, data) {
        if (responseCode == 200) {
            deviceId = null;
            Properties.setValue("deviceId", null);
            System.println("Watch unlinked successfully");
        } else {
            System.println("Unlink failed: " + responseCode);
        }
    }

    // GET /courses/public/{courseId}/compact response
    // Returns: { "teesets": [ { "_id", "name", "holes": [ { "number", "mensStrokePar", "golfDistance", "teebox", "green" } ] } ] }
    function onCompactCourseResponse(responseCode, data) {
        if (responseCode == 200 && data instanceof Dictionary) {
            var teesets = data["teesets"];
            if (teesets == null || teesets.size() == 0) {
                System.println("Compact course: no teesets found");
                return;
            }
            var teeset = teesets[0];
            var holes  = teeset["holes"];
            System.println("Compact course loaded: " + teeset["name"] + " (" + holes.size() + " holes)");
            var app = Application.getApp();
            app._selectedTeesetId   = teeset["_id"];
            app._selectedTeesetName = teeset["name"];
            app._roundState.loadParFromTeeset(holes);
            if (_nearestCourseCallback != null) {
                _nearestCourseCallback.invoke(teeset);
            }
        } else if (responseCode == 404) {
            System.println("Compact course: course not found");
        } else {
            System.println("Compact course failed: " + responseCode + "\nError: " + data);
        }
    }

    function onFetchCoursesForCacheResponse(responseCode, data) {
        if (responseCode == 200 && data instanceof Array) {
            System.println("Cache fetch complete: " + data.size() + " courses");
            if (_nearestCourseCallback != null) {
                _nearestCourseCallback.invoke(data);
            }
        } else {
            System.println("Cache fetch failed: " + responseCode);
            if (_nearestCourseCallback != null) {
                _nearestCourseCallback.invoke([]);
            }
        }
    }

    function onGetCompetitionsResponse(responseCode, data) {
        if (responseCode == 200 && data instanceof Array) {
            System.println(data);
        } else {
            System.println("get competitions failed: " + responseCode + "\nError: " + data);
        }
    }

    function onGetRoundsResponse(responseCode, data) {
        if (responseCode == 200 && data instanceof Array) {
            System.println(data);
        } else {
            System.println("get rounds failed: " + responseCode + "\nError: " + data);
        }
    }

    function onGetTeesetsResponse(responseCode, data) {
        if (responseCode == 200 && data instanceof Array) {
            System.println(data);
        } else {
            System.println("get teesets failed: " + responseCode + "\nError: " + data);
        }
    }

    function onPostRoundResponse(responseCode, data) {
        if ((responseCode == 200 || responseCode == 201) && data instanceof Dictionary) {
            System.println("Round posted successfully: " + data["id"]);
        } else {
            System.println("Post round failed: " + responseCode + "\nError: " + data);
        }
    }

    // Distance in miles between two lat/lng points
    // Uses equirectangular approximation — accurate enough within ~50 miles
    function calcDistanceMiles(lat1, lng1, lat2, lng2) {
        var R    = 3958.8;  // Earth radius in miles
        var dLat = (lat2 - lat1) * 0.01745329;  // deg to radians
        var dLng = (lng2 - lng1) * 0.01745329;
        var lat1r = lat1 * 0.01745329;
        var lat2r = lat2 * 0.01745329;

        var x = dLng * Math.cos((lat1r + lat2r) / 2.0);
        var y = dLat;
        return Math.sqrt(x * x + y * y) * R;
    }

    function onFetchNearbyCoursesResponse(responseCode, data) {
        if (responseCode != 200 || !(data instanceof Array)) {
            System.println("fetchNearbyCourses failed: " + responseCode);
            if (_nearestCourseCallback != null) {
                _nearestCourseCallback.invoke([]);
            }
            return;
        }
        // Server already filtered and limited – just pass it along
        System.println("Nearby courses found: " + data.size());
        if (_nearestCourseCallback != null) {
            _nearestCourseCallback.invoke(data);
        }
    }


    function onFetchAllCoursesResponse(responseCode, data) {
        if (responseCode == 200 && data instanceof Array) {
            if (_nearestCourseCallback != null) {
                _nearestCourseCallback.invoke(data);
            }
        } else {
            System.println("fetchAllCourses failed: " + responseCode);
        }
    }

    // ── AUTH — ORIGINAL (fallback) ────────────────────────────

    function logout() {
        if (refreshToken != null) {
            var url  = baseUrl + "/auth/logout";
            var body = { "refreshToken" => refreshToken };
            var options = {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            };
            System.println("Logging out...");
            Communications.makeWebRequest(url, body, options, method(:onLogoutResponse));
        } else {
            token = null;
            userID = null;
            refreshToken = null;
            Properties.setValue("authToken", null);
            Properties.setValue("userId", null);
            Properties.setValue("refreshToken", null);
        }
    }

    function saveCredentials(email, password) {
        Properties.setValue("savedEmail", email);
        Properties.setValue("savedPassword", password);
    }

    function loadCredentials() {
        var email    = Properties.getValue("savedEmail");
        var password = Properties.getValue("savedPassword");
        return [email, password];
    }

    // POST /auth/login — fallback only, returns full user profile
    function login() {
        var url      = baseUrl + "/auth/login";
        var email    = WatchUi.loadResource(Rez.Strings.user_email);
        var password = WatchUi.loadResource(Rez.Strings.user_password);
        Properties.setValue("userEmail", email);
        Properties.setValue("userPassword", password);
        System.println(email);
        if (email == null || password == null) {
            System.println("Set user email/password.");
            return;
        }
        var body = { "email" => email, "password" => password };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Logging in (standard)...");
        Communications.makeWebRequest(url, body, options, method(:onLoginResponse));
    }

    // ── AUTH — GARMIN ENDPOINTS ───────────────────────────────

    // POST /users/garmin/login/light
    // Preferred first login — returns JWT only (no full user profile)
    function loginLight() {
        var url      = baseUrl + "/users/garmin/login/light";
        var email    = WatchUi.loadResource(Rez.Strings.user_email);
        var password = WatchUi.loadResource(Rez.Strings.user_password);
        if (email == null || password == null) {
            System.println("No credentials — falling back to standard login");
            login();
            return;
        }
        var body = { "email" => email, "password" => password };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Logging in (light)...");
        Communications.makeWebRequest(url, body, options, method(:onLoginLightResponse));
    }

    // POST /users/garmin/login/device
    // Used after pairing — authenticates by hardware device ID
    // 404 response means not linked yet, triggers pairing flow
    function loginDevice() {
        if (deviceId == null) {
            System.println("No device ID — falling back to light login");
            loginLight();
            return;
        }
        var url  = baseUrl + "/users/garmin/login/device";
        var body = { "garminDeviceId" => deviceId };  // field name per API docs
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Logging in (device)...");
        Communications.makeWebRequest(url, body, options, method(:onLoginDeviceResponse));
    }

    // POST /users/garmin/pairing/initiate
    // Call when device login returns 404 — generates 6-char pairing code
    // No auth required — watch has no token at this point
    function initiatePairing() {
        if (deviceId == null) {
            System.println("No device ID — cannot initiate pairing");
            return;
        }
        var url  = baseUrl + "/users/garmin/pairing/initiate";
        var body = { "garminDeviceId" => deviceId };  // field name per API docs
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Initiating pairing...");
        Communications.makeWebRequest(url, body, options, method(:onPairingInitiateResponse));
    }

    // POST /users/garmin/pairing/complete
    // Called by the web app to link a watch to an account using the 6-char code.
    // Requires a valid JWT (the web-app user). On the watch side this is only
    // needed if the watch itself is completing the pairing (unusual — normally
    // the web app does this and the watch just polls status).
    function completePairing(code) {
        if (token == null) {
            System.println("No token — cannot complete pairing from watch");
            return;
        }
        var url  = baseUrl + "/users/garmin/pairing/complete";
        var body = { "pairingCode" => code };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Completing pairing with code: " + code);
        Communications.makeWebRequest(url, body, options, method(:onCompletePairingResponse));
    }

    // GET /users/garmin/pairing/status?code=XXXXXX
    // Poll every ~5 seconds while showing pairing code on screen
    // status: "pending" | "linked" | "expired"
    function checkPairingStatus(callback) {
        if (pairingCode == null) {
            System.println("No pairing code — call initiatePairing() first");
            return;
        }
        var url = baseUrl + "/users/garmin/pairing/status?code=" + pairingCode;
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Checking pairing status...");
        Communications.makeWebRequest(url, {}, options,
            callback != null ? callback : method(:onPairingStatusResponse));
    }

    // GET /users/garmin/link-status
    // Check if this watch is linked — requires auth token
    function checkLinkStatus() {
        if (token == null) {
            System.println("No token - please log in first");
            return;
        }
        var url = baseUrl + "/users/garmin/link-status";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Checking link status...");
        Communications.makeWebRequest(url, {}, options, method(:onLinkStatusResponse));
    }

    // DELETE /users/garmin/link
    // Unlink this watch — after this, next loginDevice() will get 404
    function unlinkDevice() {
        if (token == null) {
            System.println("No token - please log in first");
            return;
        }
        var url = baseUrl + "/users/garmin/link";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_DELETE,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Unlinking device...");
        Communications.makeWebRequest(url, {}, options, method(:onUnlinkResponse));
    }

    // ── USERS ─────────────────────────────────────────────────

    function getUsers() {
        if (token == null) { System.println("No token - please log in first"); return; }
        var url = baseUrl + "/users/" + userID;
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Fetching user...");
        Communications.makeWebRequest(url, {}, options, method(:onReceive));
    }

    // ── COURSES ───────────────────────────────────────────────

    function fetchPublicCourses() {
        if (token == null) { System.println("No token, please log in first"); return; }
        var url = baseUrl + "/courses/public";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Fetching courses...");
        Communications.makeWebRequest(url, {}, options, method(:onReceive));
    }

    // GET /courses/public/search?name={name}
    // No auth required — returns full course detail including teesets and holes
    function fetchCourseByName(name, callback) {
        _nearestCourseCallback = callback;
        _lastSearchQuery = name;
        var url    = baseUrl + "/courses/public/search";
        var params = { "q" => name };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Searching course by name: " + name);
        Communications.makeWebRequest(url, params, options, method(:onFetchCourseByNameResponse));
    }

    function onFetchCourseByNameResponse(responseCode, data) {
        System.println("SEARCH: onFetchCourseByNameResponse code=" + responseCode);
        var results = null;
        if (responseCode == 200 && data != null) {
            var _dbg = data.toString(); System.println("SEARCH: data=" + _dbg.substring(0, _dbg.length() < 60 ? _dbg.length() : 60));
            var raw = (data instanceof Array) ? data : [data];
            results = [];
            for (var i = 0; i < raw.size(); i++) {
                var c = raw[i];
                if (c instanceof Dictionary && c["name"] != null) {
                    var cid = c["id"] != null ? c["id"] : c["_id"];
                    results.add({ "id" => cid, "name" => c["name"] });
                }
            }
            System.println("SEARCH: parsed " + results.size() + " result(s)");
        } else {
            System.println("SEARCH: fetchCourseByName failed code=" + responseCode);
        }
        if (results != null && results.size() > 1 && _lastSearchQuery != null) {
            var q = _lastSearchQuery.toLower();
            for (var i = 0; i < results.size(); i++) {
                var n = results[i]["name"].toLower();
                var score = 2;
                if (n.substring(0, q.length() < n.length() ? q.length() : n.length()).equals(q)) {
                    score = 0;
                } else if (n.find(q) != null) {
                    score = 1;
                }
                results[i]["_score"] = score;
            }
            for (var i = 0; i < results.size() - 1; i++) {
                for (var j = 0; j < results.size() - 1 - i; j++) {
                    if (results[j]["_score"] > results[j + 1]["_score"]) {
                        var tmp = results[j];
                        results[j] = results[j + 1];
                        results[j + 1] = tmp;
                    }
                }
            }
        }
        System.println("SEARCH: callback null? " + (_nearestCourseCallback == null));
        if (_nearestCourseCallback != null) {
            System.println("SEARCH: invoking callback with " + (results == null ? "[]" : results.size() + " results"));
            _nearestCourseCallback.invoke(results != null ? results : []);
            System.println("SEARCH: callback done");
        }
    }

    // GET /courses/public/{courseId}/compact
    // No auth required — returns teesets array (each with name, _id, holes)
    // Used to populate the teeset picker after a course search selection
    function fetchTeesetsForCourse(courseId, callback) {
        if (courseId == null) {
            System.println("TEESETS: null courseId");
            if (callback != null) { callback.invoke([]); }
            return;
        }
        _nearestCourseCallback = callback;
        var url = baseUrl + "/courses/public/" + courseId + "/compact";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Fetching teesets via compact: " + courseId);
        Communications.makeWebRequest(url, {}, options, method(:onFetchTeesetsForCourseResponse));
    }

    function onFetchTeesetsForCourseResponse(responseCode, data) {
        System.println("TEESETS: compact response=" + responseCode);
        var teesets = [];
        if (responseCode == 200 && data instanceof Dictionary) {
            var raw = data["teesets"];
            if (raw instanceof Array) {
                teesets = raw;
            }
        } else {
            System.println("TEESETS: compact fetch failed code=" + responseCode);
        }
        if (_nearestCourseCallback != null) {
            _nearestCourseCallback.invoke(teesets);
        }
    }

    // GET /courses/public/{courseId}
    // No auth required — returns id, name, shortName, numHoles, geoLocation
    function fetchCourseById(courseId, callback) {
        var url = baseUrl + "/courses/public/" + courseId;
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Fetching course by ID: " + courseId);
        Communications.makeWebRequest(url, {}, options,
            callback != null ? callback : method(:onFetchCourseByIdResponse));
    }

    function onFetchCourseByIdResponse(responseCode, data) {
        if (responseCode == 200 && data instanceof Array && data.size() > 0) {
            var course = data[0];
            System.println("Course: " + course["name"] + " (" + course["numHoles"] + " holes)");
            var geo = course["geoLocation"];
            if (geo != null) {
                System.println("Location: " + geo["lat"] + ", " + geo["lng"]);
            }
        } else if (responseCode == 404) {
            System.println("Course not found");
        } else {
            System.println("fetchCourseById failed: " + responseCode + "\nError: " + data);
        }
    }

    // GET /courses/public/{courseId}/compact
    // No auth required — returns par + coordinates per hole, minimal payload
    function fetchCompactCourse(courseName, callback) {
        _nearestCourseCallback = callback;
        var url = baseUrl + "/courses/public/" + courseName + "/compact";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Fetching compact course: " + courseName);
        Communications.makeWebRequest(url, {}, options, method(:onCompactCourseResponse));
    }

    // GET /courses/public/nearby?lat={lat}&lng={lng}&radius={km}&limit={n}
    // No auth required — returns courses sorted by distance ascending
    function fetchNearbyCourses(callback) {
        var location = Position.getInfo();
        if (location == null || location.position == null) {
            System.println("No GPS fix yet");
            if (callback != null) { callback.invoke([]); }
            return;
        }
        var coords = location.position.toDegrees();
        var lat = coords[0];
        var lng = coords[1];
        // Demo dummy coords: var lat = 46.7384; var lng = -117.142;
        _pendingLat = lat;
        _pendingLng = lng;
        _nearestCourseCallback = callback;

        var params = {
            "lat"    => lat,
            "lng"    => lng,
            "radius" => 50,
            "limit"  => 10
        };
        var url = baseUrl + "/courses/public/nearby";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Fetching nearby courses lat=" + lat + " lng=" + lng);
        Communications.makeWebRequest(url, params, options, method(:onFetchNearbyCoursesResponse));
    }
    
    // GET /courses/public?limit=100
    // Used to populate the local course cache — raw list, no distance filtering
    function fetchCoursesForCache(callback) {
        if (token == null) { System.println("No token"); return; }
        _nearestCourseCallback = callback;
        var url = baseUrl + "/courses/public?limit=10";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Fetching courses for cache...");
        Communications.makeWebRequest(url, {}, options, method(:onFetchCoursesForCacheResponse));
    }

    // Fetches compact course list for name search — name field included in compact response
    function fetchAllCoursesForSearch(callback) {
        if (token == null) { System.println("No token"); return; }
        _nearestCourseCallback = callback;
        var url = baseUrl + "/courses/public/compact/?limit=8";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Fetching all courses for search...");
        Communications.makeWebRequest(url, {}, options, method(:onFetchAllCoursesResponse));
    }


    // ── TEESETS ───────────────────────────────────────────────

    function fetchTeesets() {
        if (token == null) { System.println("No token - please log in first"); return; }
        var url = baseUrl + "/teesets";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Fetching teesets...");
        Communications.makeWebRequest(url, {}, options, method(:onGetTeesetsResponse));
    }

    function fetchTeesetById(teesetId, callback) {
        if (token == null) { System.println("No token - please log in first"); return; }
        var url = baseUrl + "/teesets/" + teesetId;
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Fetching teeset by ID: " + teesetId);
        Communications.makeWebRequest(url, {}, options, callback);
    }

    function fetchTeesetHoles(teesetId, callback) {
        if (token == null) { System.println("No token - please log in first"); return; }
        var url = baseUrl + "/teesets/" + teesetId + "/holes";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Fetching teeset holes: " + teesetId);
        Communications.makeWebRequest(url, {}, options, callback);
    }

    function fetchTeesetsByCourse(courseId, callback) {
        if (token == null) { System.println("No token - please log in first"); return; }
        var url = baseUrl + "/teesets?courseId=" + courseId + "&limit=20";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Fetching teesets for course: " + courseId);
        Communications.makeWebRequest(url, {}, options, callback);
    }

    // ── ROUNDS ────────────────────────────────────────────────

    function fetchMyRounds(callback) {
        if (token == null) { System.println("No token - please log in first"); return; }
        var url = baseUrl + "/rounds";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Fetching rounds...");
        Communications.makeWebRequest(url, {}, options, callback != null ? callback : method(:onGetRoundsResponse));
    }

    function fetchRoundById(roundId, callback) {
        if (token == null) { System.println("No token - please log in first"); return; }
        var url = baseUrl + "/rounds/" + roundId;
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Fetching round: " + roundId);
        Communications.makeWebRequest(url, {}, options, callback != null ? callback : method(:onGetRoundsResponse));
    }

    function fetchRoundHoles(roundId, callback) {
        if (token == null) { System.println("No token - please log in first"); return; }
        var url = baseUrl + "/rounds/" + roundId + "/holes";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Fetching holes for round: " + roundId);
        Communications.makeWebRequest(url, {}, options, callback);
    }

    function postRound(roundState, callback) {
        if (token == null) { System.println("No token - please log in first"); return; }
        var app      = Application.getApp();
        var courseId = app._selectedCourseId;
        var teesetId = app._selectedTeesetId;

        var holeData = roundState.getHoleData();
        var byHole   = [];
        for (var i = 0; i < holeData.size(); i++) {
            byHole.add({
                "number"  => holeData[i]["number"],
                "strokes" => holeData[i]["strokes"],
                "time"    => holeData[i]["time"],
                "putts"   => 0
            });
        }

        var now     = Time.now();
        var info    = Gregorian.info(now, Time.FORMAT_SHORT);
        var dateStr = info.year.format("%04d") + "-" +
                      info.month.format("%02d") + "-" +
                      info.day.format("%02d") + "T00:00:00.000Z";

        System.println(dateStr);
        var url  = baseUrl + "/rounds";
        var body = {
            "courseId"           => courseId == null ? "689f85ac21559bd5c79bcd40" : courseId,
            "teeId"              => teesetId == null ? "66afd351a2301f542c5d317e" : teesetId,
            "playerId"           => userID,
            "date"               => dateStr,
            "distance"           => 0,
            "numHoles"           => roundState.totalHoles.toString(),
            "strokes"            => roundState.strokeCount,
            "time"               => roundState.elapsedSeconds,
            "roundType"          => "Practice",
            "notes"              => "",
            "isAnalysisByHoleOn" => true,
            "isPrivate"          => false,
            "isShotInfoEnabled"  => false,
            "analysisByHole"     => byHole
        };
        var options = {
            :method  => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Posting round — courseId=" + body["courseId"] + " teeId=" + body["teeId"] + " playerId=" + body["playerId"] + " holes=" + byHole.size() + " strokes=" + body["strokes"] + " numHoles=" + body["numHoles"]);
        _pendingRoundState    = roundState;
        _pendingRoundCallback = callback;
        Communications.makeWebRequest(url, body, options, method(:onPostRoundWithHoles));
    }

    function onPostRoundWithHoles(responseCode, data) {
        // Fire the original caller's callback first
        if (_pendingRoundCallback != null) {
            _pendingRoundCallback.invoke(responseCode, data);
        }

        if ((responseCode == 200 || responseCode == 201) && data instanceof Dictionary) {
            var roundId = data["id"];
            System.println("Round posted: " + roundId);
            if (roundId != null && _pendingRoundState != null) {
                _postRoundHoles(roundId, _pendingRoundState);
            }
        } else {
            System.println("Post round failed: " + responseCode);
        }

        _pendingRoundState    = null;
        _pendingRoundCallback = null;
    }

    hidden function _postRoundHoles(roundId, roundState) {
        var holeData = roundState.getHoleData();
        System.println("Posting " + holeData.size() + " holes for round " + roundId);
        for (var i = 0; i < holeData.size(); i++) {
            var hole    = holeData[i];
            var url     = baseUrl + "/rounds/" + roundId + "/holes";
            var body    = {
                "number"   => hole["number"],
                "strokes"  => hole["strokes"],
                "time"     => hole["time"],
                "putts"    => 0,
                "shotInfo" => []
            };
            var options = {
                :method  => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => {
                    "Authorization" => "Bearer " + token,
                    "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            };
            Communications.makeWebRequest(url, body, options, method(:onPostRoundHoleResponse));
        }
    }

    function onPostRoundHoleResponse(responseCode, data) {
        if (responseCode == 200 || responseCode == 201) {
            System.println("Hole posted ok");
        } else {
            System.println("Post hole failed: " + responseCode + " " + data);
        }
    }

    // ── COMPETITIONS ──────────────────────────────────────────

    function fetchCompetitions(callback) {
        if (token == null) { System.println("No token - please log in first"); return; }
        var url = baseUrl + "/competitions?limit=1";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(url, {}, options, callback);
    }

    function fetchPublicCompetitions(callback) {
        if (token == null) { System.println("No token, please log in first"); return; }
        var url = baseUrl + "/competitions/public?limit=5";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Fetching competitions...");
        Communications.makeWebRequest(url, {}, options, callback);
    }
}