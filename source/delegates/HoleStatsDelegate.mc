using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Timer;
using Toybox.Application;


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
        var app = Application.getApp();
        if (app.isOutOfOrderPlay() && _roundState.getHoleData().size() < _roundState.totalHoles) {
            _screenManager.goToActiveHole();
            WatchUi.pushView(
                new HoleJumperView(_roundState.totalHoles, _roundState.getHoleData()),
                new HoleJumperDelegate(_roundState),
                WatchUi.SLIDE_UP
            );
        } else if (app.isOutOfOrderPlay()) {
            _screenManager.goToRoundSummary();
        } else if (_roundState.isComplete) {
            _screenManager.goToRoundSummary();
        } else {
            _screenManager.goToActiveHole();
        }
        return true;
    }
}