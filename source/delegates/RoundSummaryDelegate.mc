using Toybox.WatchUi;
using Toybox.Application;

class RoundSummaryDelegate extends WatchUi.BehaviorDelegate {
    hidden var _screenManager;
    hidden var _view;

    function initialize(screenManager, view) {
        BehaviorDelegate.initialize();
        _screenManager = screenManager;
        _view          = view;
        Application.getApp().stopTimer();
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_UP) {
            _view.nextPage();
            return true;
        }

        if (key == WatchUi.KEY_DOWN) {
            _view.prevPage();
            return true;
        }

        if (key == WatchUi.KEY_ENTER) {
            var app = Application.getApp();
            if (app.isPracticeMode()) {
                _screenManager.goToLoading();
            } else {
                app._apiClient.postRound(app.getRoundState(), method(:onPostComplete));
                _screenManager.goToLoading();
            }
            return true;
        }

        if (key == WatchUi.KEY_ESC) {
            _screenManager.goToLoading();
            return true;
        }

        return false;
    }

    function onPostComplete(responseCode, data) {
        System.println("Post complete: " + responseCode + " data=" + data);
    }
}