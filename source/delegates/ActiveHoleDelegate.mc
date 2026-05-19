using Toybox.WatchUi;
using Toybox.Application;

class ActiveHoleDelegate extends WatchUi.BehaviorDelegate {
    hidden var _screenManager;
    hidden var _roundState;

    function initialize(screenManager) {
        BehaviorDelegate.initialize();
        _screenManager = screenManager;
        _roundState    = Application.getApp().getRoundState();
    }

    function onTap(clickEvent) {
        if (_roundState.isPaused) { return true; }
        if (_roundState.autoSwingUntil > 0 && _roundState.elapsedSeconds < _roundState.autoSwingUntil) {
            _roundState.removeStroke();
            _roundState.autoSwingUntil = 0;
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
            _roundState.advanceHole();
            if (_roundState.isComplete) {
                _screenManager.goToRoundSummary();
            } else if (Application.getApp().isBulkEntryMode()) {
                _screenManager.goToStrokeEntry(_roundState.holeNumber - 1);
            } else if (Application.getApp().showStatsAfterHole()) {
                _screenManager.goToHoleStats(_roundState, 8000);
            } else {
                WatchUi.requestUpdate();
            }
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

    hidden function _showPauseMenu() {
        var menu = new WatchUi.Menu2({:title => "Paused"});
        menu.addItem(new WatchUi.MenuItem("Resume",    null, :resume,   {}));
        menu.addItem(new WatchUi.MenuItem("View info", null, :viewInfo, {}));  // ADD THIS
        menu.addItem(new WatchUi.MenuItem("Settings",  null, :settings, {}));
        menu.addItem(new WatchUi.MenuItem("End round", null, :endRound, {}));
        WatchUi.pushView(menu, new PauseMenuDelegate(_screenManager, _roundState), WatchUi.SLIDE_UP);
    }
}