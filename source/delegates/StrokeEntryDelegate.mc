using Toybox.WatchUi;
using Toybox.Application;

class StrokeEntryDelegate extends WatchUi.BehaviorDelegate {
    hidden var _screenManager;
    hidden var _holeNumber;
    hidden var _view;

    function initialize(screenManager, holeNumber, view) {
        BehaviorDelegate.initialize();
        _screenManager = screenManager;
        _holeNumber    = holeNumber;
        _view          = view;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();

        // UP — add stroke
        if (key == WatchUi.KEY_UP) {
            _view.addStroke();
            WatchUi.requestUpdate();
            return true;
        }

        // DOWN — remove stroke
        if (key == WatchUi.KEY_DOWN) {
            _view.removeStroke();
            WatchUi.requestUpdate();
            return true;
        }

        // ENTER — save strokes and go back to active hole
        if (key == WatchUi.KEY_ENTER) {
            var strokes    = _view.getStrokes();
            var roundState = Application.getApp().getRoundState();
            var holeData   = roundState.getHoleData();
            for (var i = 0; i < holeData.size(); i++) {
                if (holeData[i]["number"] == _holeNumber) {
                    holeData[i]["strokes"] = strokes;
                    roundState.strokeCount += strokes;
                    break;
                }
            }
            if (Application.getApp().showStatsAfterHole()) {
                _screenManager.goToHoleStats(roundState, 8000);
            } else {
                _screenManager.goToActiveHole();
            }
            return true;
        }

        return false;
    }
}