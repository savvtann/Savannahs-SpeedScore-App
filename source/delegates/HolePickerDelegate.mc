using Toybox.WatchUi;
using Toybox.Application;

class HolePickerDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _teesetId;
    hidden var _teesetName;
    hidden var _holes;

    function initialize(teesetId, teesetName, holes) {
        Menu2InputDelegate.initialize();
        _teesetId   = teesetId;
        _teesetName = teesetName;
        _holes      = holes;
    }

    function onSelect(item) {
        var startHole = item.getId();
        var app = Application.getApp();
        app.setSelectedTeeset(_teesetId, _teesetName, null);
        app.startRound();
        app._roundState.setStartHole(startHole);
        if (_holes != null) {
            app._roundState.loadParFromTeeset(_holes);
        }
        System.println("ROUND: starting at hole " + startHole);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
