using Toybox.WatchUi;
using Toybox.Application.Properties;

class SwingSensitivityDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId();
        if (id == :sensitivityLow) {
            Properties.setValue("swingDetectionSensitivity", 0);
        } else if (id == :sensitivityMedium) {
            Properties.setValue("swingDetectionSensitivity", 1);
        } else if (id == :sensitivityHigh) {
            Properties.setValue("swingDetectionSensitivity", 2);
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
