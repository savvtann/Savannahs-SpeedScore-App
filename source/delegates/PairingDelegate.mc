using Toybox.WatchUi;
using Toybox.Timer;
using Toybox.Application;
using Toybox.Lang;

class PairingDelegate extends WatchUi.BehaviorDelegate {
    hidden var _view;
    hidden var _timer;

    function initialize(view, initiateNow) {
        BehaviorDelegate.initialize();
        _view  = view;
        _timer = new Timer.Timer();
        _timer.start(method(:onPollTick), 5000, true);
        if (initiateNow) {
            Application.getApp()._apiClient.initiatePairing();
        }
    }

    function onPollTick() {
        _view.advanceDot();
        WatchUi.requestUpdate();
        Application.getApp()._apiClient.checkPairingStatus(method(:onStatusResponse));
    }

    function onStatusResponse(responseCode, data) {
        if (responseCode == 200 && data instanceof Dictionary) {
            var status = data["status"];
            System.println("Pairing poll: " + status);
            if (status.equals("linked")) {
                _timer.stop();
                var api = Application.getApp()._apiClient;
                api.clearPairingView();
                api.loginDevice();
                WatchUi.popView(WatchUi.SLIDE_DOWN);
            } else if (status.equals("expired")) {
                // Request a fresh code — onPairingInitiateResponse updates the view in place
                Application.getApp()._apiClient.initiatePairing();
            }
            // "pending" — keep polling, nothing to do
        } else {
            System.println("Pairing status poll failed: " + responseCode);
        }
    }

    function onBack() {
        _timer.stop();
        Application.getApp()._apiClient.clearPairingView();
        return false;  // let WatchUi pop the view — user lands on Home
    }
}
