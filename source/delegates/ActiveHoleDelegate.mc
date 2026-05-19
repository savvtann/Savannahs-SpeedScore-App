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
            if (!Application.getApp().isPostHoleEntryMode()) {
                _roundState.addStroke();
                WatchUi.requestUpdate();
            }
            return true;
        }

        if (key == WatchUi.KEY_DOWN) {
            if (!Application.getApp().isPostHoleEntryMode()) {
                _roundState.removeStroke();
                WatchUi.requestUpdate();
            }
            return true;
        }

        if (key == WatchUi.KEY_ENTER) {
            _roundState.advanceHole();
            var app = Application.getApp();
            if (app.isPostHoleEntryMode()) {
                var hd = _roundState.getHoleData();
                _screenManager.goToStrokeEntry(hd[hd.size() - 1]["number"]);
            } else if (app.showStatsAfterHole()) {
                _screenManager.goToHoleStats(_roundState, 8000);
            } else if (app.isOutOfOrderPlay()) {
                if (_roundState.getHoleData().size() >= _roundState.totalHoles) {
                    _screenManager.goToRoundSummary();
                } else {
                    var view = new HoleJumperView(_roundState.totalHoles, _roundState.getHoleData());
                    WatchUi.pushView(view, new HoleJumperDelegate(_roundState), WatchUi.SLIDE_UP);
                }
            } else if (_roundState.isComplete) {
                _screenManager.goToRoundSummary();
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