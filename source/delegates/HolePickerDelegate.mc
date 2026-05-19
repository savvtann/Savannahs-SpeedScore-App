using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Timer;

class HolePickerDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _teesetId;
    hidden var _teesetName;
    hidden var _holes;
    hidden var _pendingStartHole;
    hidden var _timer;

    function initialize(teesetId, teesetName, holes) {
        Menu2InputDelegate.initialize();
        _teesetId         = teesetId;
        _teesetName       = teesetName;
        _holes            = holes;
        _pendingStartHole = 1;
        _timer            = null;
    }

    function onSelect(item) {
        _pendingStartHole = item.getId();
        Application.getApp().setSelectedTeeset(_teesetId, _teesetName, null);
        // Defer startRound() so it runs after the Menu2 event loop exits.
        // Calling switchToView from inside Menu2InputDelegate.onSelect crashes.
        _timer = new Timer.Timer();
        _timer.start(method(:_beginRound), 1, false);
    }

    function _beginRound() {
        var app = Application.getApp();
        app.startRound();
        app._roundState.setStartHole(_pendingStartHole);
        if (_holes != null) {
            app._roundState.loadParFromTeeset(_holes);
        }
        System.println("ROUND: starting at hole " + _pendingStartHole);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
