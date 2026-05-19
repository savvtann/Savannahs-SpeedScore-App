using Toybox.WatchUi as Ui;
using Toybox.Application;

class TeesetMenuDelegate extends Ui.Menu2InputDelegate {
    hidden var _teesets;

    function initialize(teesets) {
        Menu2InputDelegate.initialize();
        _teesets = teesets;
    }

    function onSelect(item) {
        var idx      = item.getId();
        var teeset   = _teesets[idx];
        var teesetId = teeset["_id"];
        var name     = teeset["name"] != null ? teeset["name"] : "Tee " + (idx + 1);
        var holes    = teeset["holes"];
        var numHoles = (holes != null) ? holes.size() : 18;

        Application.getApp()._roundFlowDepth++;
        WatchUi.pushView(
            new HolePickerView(numHoles),
            new HolePickerDelegate(teesetId, name, holes),
            WatchUi.SLIDE_LEFT
        );
    }
    function onBack() {
        Ui.popView(Ui.SLIDE_RIGHT);
    }
}