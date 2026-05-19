import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Timer;
import Toybox.Time;
using Toybox.Position;
using Toybox.Application.Properties;

class Garmin_SpeedScoreApp extends Application.AppBase {
    hidden var _screenManager;
    hidden var _timer;
    hidden var _swingDetector = null;
    var _apiClient;
    var _roundState;
    var _selectedCourseId   = null;
    var _selectedCourseName = null;
    var _selectedTeesetId   = null;
    var _selectedTeesetName = null;
    var _roundFlowDepth     = 0;

    function initialize() {
        System.println("=== APP INITIALIZE ===");
        AppBase.initialize();
        _roundState    = new RoundState();
        _apiClient     = new APIClient();
        _screenManager = new ScreenManager();
    }

    function onStart(state) {
        System.println("=== APP ONSTART ===");
        startPositioning();
        var token = Properties.getValue("authToken");
        if (token != null && !token.equals("")) {
            // Previously linked — try device login in background; 404 will push pairing if needed
            _apiClient.loginDevice();
        } else {
            // Never linked — show pairing screen immediately, initiate in background
            var view = new PairingView(null);
            _apiClient._pairingView = view;
            _apiClient.initiatePairing();
            WatchUi.pushView(view, new PairingDelegate(view, false), WatchUi.SLIDE_UP);
        }
    }

    function onStop(state) {
        System.println("=== APP ONSTOP ===");
        stopTimer();
        stopSwingDetector();
    }

    function getInitialView() {
        System.println("=== APP GET INITIAL VIEW ===");
        return [_screenManager.getInitialView(), _screenManager.getInitialDelegate()];
    }

    // ── STATIC COURSE LIST (add your own courses here) ──────
    function getStaticCourses() {
        return [
            {
                "id"   => "689f85ac21559bd5c79bcd40",
                "name" => "Golf Park Tervuren",
                "lat"  => 50.8242,
                "lon"  => 4.5241
            },
            {
                "id"   => "507f1f77bcf86cd799439011",
                "name" => "Royal Waterloo",
                "lat"  => 50.7123,
                "lon"  => 4.3985
            }
        ];
    }

    // ── LOCAL SEARCH (no network calls) ─────────────────────
    function searchNearbyCoursesFromStaticList(callback) {
        var location = Position.getInfo();
        if (location == null || location.position == null) {
            System.println("No GPS fix yet");
            if (callback != null) {
                callback.invoke([]);
            }
            return;
        }

        var coords = location.position.toDegrees();
        var userLat = coords[0];
        var userLng = coords[1];
        
        var allCourses = getStaticCourses();
        var nearby = [];
        
        for (var i = 0; i < allCourses.size(); i++) {
            var course = allCourses[i];
            var dist = _apiClient.calcDistanceMiles(userLat, userLng, course["lat"], course["lon"]);
            if (dist <= 3.0) {
                nearby.add({
                    "id"   => course["id"],
                    "name" => course["name"],
                    "_dist" => dist
                });
            }
        }
        
        // Bubble sort by distance
        for (var i = 0; i < nearby.size() - 1; i++) {
            for (var j = 0; j < nearby.size() - 1 - i; j++) {
                if (nearby[j]["_dist"] > nearby[j+1]["_dist"]) {
                    var tmp = nearby[j];
                    nearby[j] = nearby[j+1];
                    nearby[j+1] = tmp;
                }
            }
        }
        
        if (callback != null) {
            callback.invoke(nearby);
        }
    }

    // ── COURSE SELECTION ENTRY POINT ────────────────────────
    function goToCourseSelection() {
        _apiClient.fetchNearbyCourses(method(:onStaticCoursesFound));
    }

    function onStaticCoursesFound(courses) {
        var sm = _screenManager;
        if (sm == null) {
            System.println("ERROR: _screenManager is null");
            return;
        }
        _roundFlowDepth = 1;
        var view = new CoursePickerView(courses);
        var delegate = new CoursePickerDelegate(sm, courses);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
    }

    function searchCourse(text) {
        _apiClient.fetchCourseByName(text, method(:onSearchResult));
    }

    function onSearchResult(results) {
        System.println("SEARCH: onSearchResult called, count=" + results.size());
        _roundFlowDepth++;
        WatchUi.pushView(
            new SearchResultsView(results),
            new SearchResultsDelegate(results),
            WatchUi.SLIDE_LEFT
        );
    }

    // ── ROUND MANAGEMENT ────────────────────────────────────
    function setSelectedCourse(courseId, name) {
        _selectedCourseId   = courseId;
        _selectedCourseName = name;
        System.println("Selected course: " + name);
    }

    function setSelectedTeeset(teesetId, name, holes) {
        _selectedTeesetId   = teesetId;
        _selectedTeesetName = name;
        _roundState.loadParFromTeeset(holes);
        System.println("Selected teeset: " + name);
    }

    function startRound() {
        _screenManager.startRound();
    }

    function startTimer() {
        if (_timer != null) { _timer.stop(); }
        _timer = new Timer.Timer();
        _timer.start(method(:onTick), 1000, true);
    }

    function stopTimer() {
        if (_timer != null) { _timer.stop(); }
    }

    function onTick() {
        if (!_roundState.isPaused || timerRunsDuringPause()) {
            _roundState.tick();
        }
        WatchUi.requestUpdate();
    }

    function startPositioning() {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    function onPosition(info) {
        if (info has :heading && info.heading != null) {
            _roundState.heading = info.heading;
        }
        WatchUi.requestUpdate();
    }

    function resetRound() {
        stopSwingDetector();
        _roundState = new RoundState();
        _screenManager.goToLoading();
    }

    // ── SWING DETECTOR ──────────────────────────────────────
    function startSwingDetector() {
        if (!isSwingDetectionEnabled()) { return; }
        if (_swingDetector == null) {
            _swingDetector = new SwingDetector();
        }
        _swingDetector.start();
    }

    function stopSwingDetector() {
        if (_swingDetector != null) {
            _swingDetector.stop();
        }
    }

    // ── SETTINGS HELPERS ────────────────────────────────────
    function isPostHoleEntryMode()    { return Properties.getValue("postHoleEntry") == true; }
    function isOutOfOrderPlay()   { return Properties.getValue("outOfOrderPlay") == true; }
    function isTouchInputMode()   { return Properties.getValue("touchInput") == true; }
    function showStatsAfterHole() { return Properties.getValue("statsAfterHole") == true; }
    function isPracticeMode()     { return _selectedCourseId != null && _selectedCourseId.equals("practice"); }
    function showHoleNumber()     { return Properties.getValue("showHoleNumber") != false; }
    function showPar()            { return Properties.getValue("showPar") != false; }
    function showStrokes()        { return Properties.getValue("showStrokes") != false; }
    function showRoundTimer()     { return Properties.getValue("showRoundTimer") != false; }
    function showHoleTimer()      { return Properties.getValue("showHoleTimer") != false; }
    function showSpeedScore()     { return Properties.getValue("showSpeedScore") != false; }
    function showGolfScore()      { return Properties.getValue("showGolfScore") != false; }
    function showArrow()          { return Properties.getValue("showArrow") != false; }
    function useImperial()        { return Properties.getValue("useImperial") != false; }
    function isSwingDetectionEnabled()  { return Properties.getValue("swingDetection") == true; }
    function isSwingVibrationEnabled()  { return Properties.getValue("swingVibration") != false; }
    function timerRunsDuringPause()     { return Properties.getValue("timerRunsDuringPause") == true; }
    function getSwingDetectionSensitivity() {
        var v = Properties.getValue("swingDetectionSensitivity");
        if (v == null) { return 1; }
        return v;
    }

    // ── FAVORITES (local storage) ───────────────────────────
    function getFavoriteCourses() {
        var raw = Properties.getValue("favoriteCourses");
        if (raw == null || raw.length() == 0) { return []; }
        var entries = strSplit(raw, "~");
        var favs = [];
        for (var i = 0; i < entries.size(); i++) {
            var parts = strSplit(entries[i], "|");
            if (parts.size() >= 2) {
                favs.add({ "id" => parts[0], "name" => parts[1] });
            }
        }
        return favs;
    }

    function getSortedFavoriteCourses() {
        return getFavoriteCourses();
    }

    function isFavoriteCourse(courseId) {
        var favs = getFavoriteCourses();
        for (var i = 0; i < favs.size(); i++) {
            if (favs[i]["id"].equals(courseId)) { return true; }
        }
        return false;
    }

    function toggleFavoriteCourse(courseId, courseName) {
        var favs = getFavoriteCourses();
        for (var i = 0; i < favs.size(); i++) {
            if (favs[i]["id"].equals(courseId)) {
                favs.remove(favs[i]);
                _saveFavoriteCourses(favs);
                System.println("Removed favorite: " + courseName);
                return false;
            }
        }
        favs.add({ "id" => courseId, "name" => courseName });
        _saveFavoriteCourses(favs);
        System.println("Added favorite: " + courseName);
        return true;
    }

    hidden function _saveFavoriteCourses(favs) {
        var str = "";
        for (var i = 0; i < favs.size(); i++) {
            var entry = favs[i]["id"] + "|" + favs[i]["name"];
            if (str.length() > 0) { str = str + "~"; }
            str = str + entry;
        }
        Properties.setValue("favoriteCourses", str);
    }

    // ── UTILITY ─────────────────────────────────────────────
    function strSplit(str, delim) {
        var parts = [];
        var start = 0;
        var len = str.length();
        for (var i = 0; i <= len; i++) {
            if (i == len || str.substring(i, i+1).equals(delim)) {
                parts.add(str.substring(start, i));
                start = i + 1;
            }
        }
        return parts;
    }

    function getApiClient()  { return _apiClient; }
    function getRoundState() { return _roundState; }
}