using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Timer;


class HoleStatsDelegate extends WatchUi.BehaviorDelegate {
    hidden var _screenManager;
    hidden var _roundState;

    function initialize(screenManager, roundState) {
        BehaviorDelegate.initialize();
        _screenManager = screenManager;
        _roundState    = roundState;
    }

    function onKey(keyEvent) {
        _roundState.resume();
        _screenManager.goToActiveHole();
        return true;
    }
}