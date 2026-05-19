using Toybox.WatchUi;

class HolePickerView extends WatchUi.Menu2 {
    function initialize(numHoles) {
        Menu2.initialize({:title => "Start Hole"});
        for (var i = 1; i <= numHoles; i++) {
            addItem(new WatchUi.MenuItem("Hole " + i, null, i, {}));
        }
    }
}
