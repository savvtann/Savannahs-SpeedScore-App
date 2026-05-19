using Toybox.WatchUi;
using Toybox.Application;

class PauseMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _screenManager;
    hidden var _roundState;

    function initialize(screenManager, roundState) {
        Menu2InputDelegate.initialize();
        _screenManager = screenManager;
        _roundState    = roundState;
    }

    function onSelect(item) {
        var id = item.getId();
        if (id == :resume) {
            _roundState.resume();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.requestUpdate();
        } else if (id == :viewInfo) {
            var infoView = new InfoView(_roundState);
            WatchUi.pushView(infoView, new InfoDelegate(_screenManager, _roundState, infoView), WatchUi.SLIDE_LEFT);
        } else if (id == :settings) {
            WatchUi.pushView(new SettingsView(), new SettingsDelegate(_screenManager), WatchUi.SLIDE_UP);
        } else if (id == :endRound) {
            Application.getApp().stopTimer();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            _screenManager.goToRoundSummary();
        }
    }

    function onBack() {
        _roundState.resume();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.requestUpdate();
    }
}