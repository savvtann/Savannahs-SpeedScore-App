using Toybox.WatchUi;
using Toybox.Application;

class ActiveHoleTouchDelegate extends WatchUi.InputDelegate {
    hidden var _screenManager;
    hidden var _roundState;

    // hidden const HOLE_X   = 104;
    // hidden const HOLE_Y   = 95;
    // hidden const STROKE_X = 350;
    // hidden const STROKE_Y = 95;
    // hidden const RADIUS   = 45;

    // Grid layout regions
    hidden const STROKE_X  = 329;  // 0.725 * 454
    hidden const STROKE_Y  = 154;  // h * 0.34
    hidden const STROKE_W  = 114;  // half screen width
    hidden const STROKE_H  = 100;  // tap zone height

    hidden const TIMER_X   = 125;  // 0.275 * 454
    hidden const TIMER_Y   = 154;
    hidden const TIMER_W   = 114;
    hidden const TIMER_H   = 100;

    function initialize(screenManager) {
        InputDelegate.initialize();
        _screenManager = screenManager;
        _roundState    = Application.getApp().getRoundState();
    }

    // hidden function _inCircle(tapX, tapY, cx, cy) {
    //     var dx = tapX - cx;
    //     var dy = tapY - cy;
    //     return (dx * dx + dy * dy) <= (RADIUS * RADIUS);
    // }

    hidden function _inRect(tapX, tapY, cx, cy, hw, hh) {
        return tapX >= cx - hw && tapX <= cx + hw &&
            tapY >= cy - hh && tapY <= cy + hh;
    }

    // function onTap(clickEvent) {
    //     System.println("=== TAP: " + clickEvent.getCoordinates()[0] + ", " + clickEvent.getCoordinates()[1] + " ===");
    //     if (!Application.getApp().isTouchInputMode()) { return false; }
    //     if (_roundState.isPaused) { return true; }

    //     var coords = clickEvent.getCoordinates();
    //     var x      = coords[0];
    //     var y      = coords[1];

    //     if (_inCircle(x, y, STROKE_X, STROKE_Y)) {
    //         if (!Application.getApp().isBulkEntryMode()) {
    //             _roundState.addStroke();
    //             WatchUi.requestUpdate();
    //         }
    //         return true;
    //     }

    //     if (_inCircle(x, y, HOLE_X, HOLE_Y)) {
    //         _advanceHole();
    //         return true;
    //     }

    //     return false;
    // }

    function onTap(clickEvent) {
        System.println("=== TAP: " + clickEvent.getCoordinates()[0] + ", " + clickEvent.getCoordinates()[1] + " ===");
        if (_roundState.isPaused) { return true; }

        // Any tap within the auto-swing window undoes the detected stroke,
        // regardless of whether touch input mode is enabled
        if (_roundState.autoSwingUntil > 0 && _roundState.elapsedSeconds < _roundState.autoSwingUntil) {
            _roundState.removeStroke();
            _roundState.autoSwingUntil = 0;
            WatchUi.requestUpdate();
            return true;
        }

        if (!Application.getApp().isTouchInputMode()) { return false; }

        var coords = clickEvent.getCoordinates();
        var x      = coords[0];
        var y      = coords[1];

        // Tap right cell — add stroke
        if (_inRect(x, y, STROKE_X, STROKE_Y, STROKE_W, STROKE_H)) {
            if (!Application.getApp().isBulkEntryMode()) {
                _roundState.addStroke();
                WatchUi.requestUpdate();
            }
            return true;
        }

        return false;
    }

    // function onHold(clickEvent) {
    //     if (!Application.getApp().isTouchInputMode()) { return false; }
    //     if (_roundState.isPaused) { return true; }

    //     var coords = clickEvent.getCoordinates();
    //     var x      = coords[0];
    //     var y      = coords[1];

    //     if (_inCircle(x, y, STROKE_X, STROKE_Y)) {
    //         if (!Application.getApp().isBulkEntryMode()) {
    //             _roundState.removeStroke();
    //             WatchUi.requestUpdate();
    //         }
    //         return true;
    //     }

    //     if (_inCircle(x, y, HOLE_X, HOLE_Y)) {
    //         _roundState.backAHole();
    //         WatchUi.requestUpdate();
    //         return true;
    //     }

    //     return false;
    // }

    function onHold(clickEvent) {
        if (!Application.getApp().isTouchInputMode()) { return false; }
        if (_roundState.isPaused) { return true; }

        var coords = clickEvent.getCoordinates();
        var x      = coords[0];
        var y      = coords[1];

        // Hold right cell — remove stroke
        if (_inRect(x, y, STROKE_X, STROKE_Y, STROKE_W, STROKE_H)) {
            if (!Application.getApp().isBulkEntryMode()) {
                _roundState.removeStroke();
                WatchUi.requestUpdate();
            }
            return true;
        }

        return false;
    }

    function onSwipe(swipeEvent) {
        if (!Application.getApp().isTouchInputMode()) { return false; }
        if (_roundState.isPaused) { return true; }

        var dir = swipeEvent.getDirection();
        if (dir == WatchUi.SWIPE_LEFT) {
            _advanceHole();
            return true;
        }
        if (dir == WatchUi.SWIPE_RIGHT) {
            _roundState.backAHole();
            WatchUi.requestUpdate();
            return true;
        }

        return false;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();

        if (_roundState.isPaused) {
            if (key == WatchUi.KEY_ESC) {
                _showPauseMenu();
                return true;
            }
            return true;
        }

        if (key == WatchUi.KEY_UP) {
            if (!Application.getApp().isBulkEntryMode()) {
                _roundState.addStroke();
                WatchUi.requestUpdate();
            }
            return true;
        }

        if (key == WatchUi.KEY_DOWN) {
            if (!Application.getApp().isBulkEntryMode()) {
                _roundState.removeStroke();
                WatchUi.requestUpdate();
            }
            return true;
        }

        if (key == WatchUi.KEY_ENTER) {
            _advanceHole();
            return true;
        }

        if (key == WatchUi.KEY_ESC) {
            _roundState.pause();
            WatchUi.requestUpdate();
            _showPauseMenu();
            return true;
        }

        return false;
    }

    hidden function _advanceHole() {
        _roundState.advanceHole();
        if (_roundState.isComplete) {
            _screenManager.goToRoundSummary();
            return;
        }
        if (Application.getApp().isBulkEntryMode()) {
            _screenManager.goToStrokeEntry(_roundState.holeNumber - 1);
            return;
        }
        if (Application.getApp().showStatsAfterHole()) {
            _screenManager.goToHoleStats(_roundState, 8000);
            return;
        }
        
        WatchUi.requestUpdate();
    }

    hidden function _showPauseMenu() {
        var menu = new WatchUi.Menu2({:title => "Paused"});
        menu.addItem(new WatchUi.MenuItem("Resume",    null, :resume,   {}));
        menu.addItem(new WatchUi.MenuItem("View info", null, :viewInfo, {}));
        menu.addItem(new WatchUi.MenuItem("Settings",  null, :settings, {}));
        menu.addItem(new WatchUi.MenuItem("End round", null, :endRound, {}));
        WatchUi.pushView(menu, new PauseMenuDelegate(_screenManager, _roundState), WatchUi.SLIDE_UP);
    }


}