using Toybox.WatchUi;

class TeesetPickerView extends WatchUi.Menu2 {
    hidden var _teesets;

    function initialize(teesets) {
        Menu2.initialize({:title => "Select Tee"});
        _teesets = teesets;

        if (teesets == null || teesets.size() == 0) {
            addItem(new WatchUi.MenuItem("No teesets found", null, :none, {}));
        } else {
            for (var i = 0; i < teesets.size(); i++) {
                var name = teesets[i]["name"] != null ? teesets[i]["name"] : "Tee " + (i + 1);
                addItem(new WatchUi.MenuItem(name, null, i, {}));
            }
        }
    }

    function getTeesets() { return _teesets; }
}
