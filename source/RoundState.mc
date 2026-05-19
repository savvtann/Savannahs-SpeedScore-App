using Toybox.Application;

class RoundState {
    var elapsedSeconds  = 0;
    var strokeCount     = 0;
    var holeNumber      = 1;
    var startHole       = 1;
    var totalHoles      = 18;
    var isComplete      = false;
    var heading         = 0; // 0 = north, radians
    var isPaused        = false;
    // elapsedSeconds value at which the "auto swing" indicator expires (0 = no indicator)
    var autoSwingUntil  = 0;

    hidden const DEFAULT_PARS = [4, 4, 3, 5, 4, 3, 4, 5, 4, 4, 3, 5, 4, 4, 3, 5, 4, 4];

    hidden var _parData          = [];
    hidden var _holeData         = [];
    hidden var _holeStartTime    = 0;
    hidden var _holeStartStrokes = 0;

    function initialize() {
        _holeStartTime    = 0;
        _holeStartStrokes = 0;
        _holeData         = [];
        _parData = [4, 4, 3, 5, 4, 3, 4, 5, 4, 4, 3, 5, 4, 4, 3, 5, 4, 4];

    }


    function getParDiff() {
        var parSoFar = 0;
        for (var i = 0; i < _holeData.size(); i++) {
            parSoFar += getParForHole(_holeData[i]["number"]);
        }
        parSoFar += getParForHole(holeNumber);
        var diff = strokeCount - parSoFar;
        if (diff == 0) { return "E"; }
        if (diff > 0)  { return "+" + diff; }
        return diff.toString();
    }

    function setStartHole(n) {
        if (n >= 1 && n <= totalHoles) {
            holeNumber = n;
            startHole  = n;
        }
    }

    function addStroke()    { strokeCount++; }
    function removeStroke() { if (strokeCount > 0) { strokeCount--; } }

    function advanceHole() {
        _holeData.add({
            "number"  => holeNumber,
            "strokes" => strokeCount - _holeStartStrokes,
            "time"    => elapsedSeconds - _holeStartTime
        });
        _holeStartStrokes = strokeCount;
        _holeStartTime    = elapsedSeconds;

        if (_holeData.size() >= totalHoles) {
            isComplete = true;
        } else if (holeNumber >= totalHoles) {
            holeNumber = 1;
        } else {
            holeNumber++;
        }
    }

    function backAHole() {
        if (_holeData.size() == 0) { return; }
        var lastHole = _holeData[_holeData.size() - 1];
        strokeCount    = _holeStartStrokes;
        elapsedSeconds = _holeStartTime;
        _holeData.remove(lastHole);
        holeNumber = lastHole["number"];
        isComplete = false;

        if (_holeData.size() > 0) {
            var prevHole = _holeData[_holeData.size() - 1];
            _holeStartStrokes = strokeCount - lastHole["strokes"];
            _holeStartTime    = elapsedSeconds - lastHole["time"];
        } else {
            _holeStartStrokes = 0;
            _holeStartTime    = 0;
        }
    }

    function getHoleData() { return _holeData; }

    function getPar() {
        var idx = holeNumber - 1;
        if (idx < 0 || idx >= _parData.size()) {
            System.println("getPar: invalid hole number " + holeNumber);
            return 1; // fallback
        }
        var par = _parData[idx];
        if (par == null) {
            // Should not happen after loadParFromTeeset improvements, but just in case
            System.println("getPar: null par for hole " + holeNumber + ", using default");
            par = DEFAULT_PARS[idx];
            _parData[idx] = par; // repair
        }
        return par;
    }

    function loadParFromTeeset(holes) {
        if (holes == null) {
            System.println("loadParFromTeeset: holes is null");
            return;
        }
        var womens = (Application.Properties.getValue("womensParMode") == true);
        var parKey = womens ? "womensStrokePar" : "mensStrokePar";
        System.println("loadParFromTeeset: holes size = " + holes.size() + ", key = " + parKey);
        for (var i = 0; i < holes.size() && i < 18; i++) {
            var hole     = holes[i];
            var parValue = hole[parKey];

            // Convert whatever comes back to a number
            var num = null;
            if (parValue instanceof Number) {
                num = parValue;
            } else {
                // Try converting to string then number — handles String, Long, Float, etc.
                try {
                    var str = parValue.toString();
                    if (str != null && !str.equals("") && !str.equals("null")) {
                        num = str.toNumber();
                    }
                } catch(ex) {
                    // parValue was null or had no toString — leave num as null
                }
            }

            if (num != null && num >= 3 && num <= 6) {
                // Sanity check — valid par is 3-6
                _parData[i] = num;
                System.println("  hole " + (i+1) + " par = " + num);
            } else {
                // Keep default
                System.println("  hole " + (i+1) + ": using default par " + _parData[i]);
            }
        }
    }

    function getCurrentHoleStrokes() {
        return strokeCount - _holeStartStrokes;
    }

    function getCurrentHoleTime() {
        return elapsedSeconds - _holeStartTime;
    }

    function getCurrentHoleTimeFormatted() {
        var s    = getCurrentHoleTime();
        var mins = s / 60;
        var secs = s % 60;
        return mins.format("%02d") + ":" + secs.format("%02d");
    }

    function tick() {
        if (!isPaused) {
            elapsedSeconds++;
        }
    }

    function getFormattedTime() {
        var mins = elapsedSeconds / 60;
        var secs = elapsedSeconds % 60;
        return mins.format("%02d") + ":" + secs.format("%02d");
    }

    function getSpeedScore() {
        var mins = elapsedSeconds / 60;
        return strokeCount + mins;
    }

    function getParForHole(holeNum) {
        var idx = holeNum - 1;
        if (idx < 0 || idx >= _parData.size()) { return 4; }
        var par = _parData[idx];
        return par != null ? par : 4;
    }

    function pause() { isPaused = true; }
    function resume() { isPaused = false; }
    function togglePause() { isPaused = !isPaused; }
}