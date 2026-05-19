using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Application.Properties;

class SettingsDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _screenManager;

    function initialize(screenManager) {
        Menu2InputDelegate.initialize();
        _screenManager = screenManager;
    }

    function onSelect(item) {
        var id = item.getId();
        if (id == :outOfOrderPlay) {
            Properties.setValue("outOfOrderPlay", item.isEnabled());
            System.println("Out of order play: " + item.isEnabled());
        } else if (id == :postHoleEntry) {
            Properties.setValue("postHoleEntry", item.isEnabled());
            System.println("Post-Hole entry: " + item.isEnabled());
        } else if (id == :touchInput) {
            Properties.setValue("touchInput", item.isEnabled());
            System.println("Touch input: " + item.isEnabled());
        } else if (id == :displayOptions) {
            WatchUi.pushView(new DisplayOptionsView(), new DisplayOptionsDelegate(_screenManager), WatchUi.SLIDE_LEFT);
        } else if (id == :statsAfterHole) {
            Properties.setValue("statsAfterHole", item.isEnabled());
            System.println("Stats after hole: " + item.isEnabled());
        } else if (id == :useImperial) {
            Properties.setValue("useImperial", item.isEnabled());
            System.println("Imperial: " + item.isEnabled());
        } else if (id == :womensParMode) {
            Properties.setValue("womensParMode", item.isEnabled());
            System.println("Womens par: " + item.isEnabled());
        } else if (id == :swingDetection) {
            Properties.setValue("swingDetection", item.isEnabled());
            System.println("Swing detection: " + item.isEnabled());
        } else if (id == :swingVibration) {
            Properties.setValue("swingVibration", item.isEnabled());
            System.println("Swing vibration: " + item.isEnabled());
        } else if (id == :linkWatch) {
            var api  = Application.getApp()._apiClient;
            var view = new PairingView(null);
            api._pairingView = view;
            WatchUi.pushView(view, new PairingDelegate(view, true), WatchUi.SLIDE_LEFT);
        } else if (id == :timerRunsDuringPause) {
            Properties.setValue("timerRunsDuringPause", item.isEnabled());
            System.println("Timer runs during pause: " + item.isEnabled());
        } else if (id == :swingDetectionSensitivity) {
            // Cycle Low(0) → Medium(1) → High(2) → Low and update the subtitle in place.
            // A sub-menu would leave the Settings subtitle stale after popping back.
            var current = Properties.getValue("swingDetectionSensitivity");
            if (current == null) { current = 1; }
            var next = (current + 1) % 3;
            Properties.setValue("swingDetectionSensitivity", next);
            var labels = ["Low", "Medium", "High"];
            item.setSubLabel(labels[next]);
            System.println("Swing sensitivity: " + labels[next]);
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}