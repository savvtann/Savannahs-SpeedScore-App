using Toybox.WatchUi;
using Toybox.Application.Properties;

class SwingSensitivityView extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title => "Swing Sensitivity"});

        var current = Properties.getValue("swingDetectionSensitivity");

        addItem(new WatchUi.MenuItem("Low",    "Full swings only", :sensitivityLow,    {}));
        addItem(new WatchUi.MenuItem("Medium", "Most shots",       :sensitivityMedium, {}));
        addItem(new WatchUi.MenuItem("High",   "Chips & putts",    :sensitivityHigh,   {}));
    }
}
