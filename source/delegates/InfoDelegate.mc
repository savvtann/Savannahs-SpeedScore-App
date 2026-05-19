using Toybox.WatchUi;
using Toybox.Application;

class InfoDelegate extends WatchUi.BehaviorDelegate {
    hidden var _screenManager;
    hidden var _roundState;
    hidden var _view;

    function initialize(screenManager, roundState, view) {
        BehaviorDelegate.initialize();
        _screenManager = screenManager;
        _roundState    = roundState;
        _view          = view;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_UP) {
            _view.prevPage();
            return true;
        }

        if (key == WatchUi.KEY_DOWN) {
            _view.nextPage();
            return true;
        }

        if (key == WatchUi.KEY_ESC) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }

        return false;
    }
}