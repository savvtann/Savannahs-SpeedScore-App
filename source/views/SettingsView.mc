using Toybox.WatchUi;
using Toybox.Application.Properties;

class SettingsView extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title => "Settings"});
        addItem(new WatchUi.MenuItem(
            "Link watch",
            "Pair with SpeedScore",
            :linkWatch,
            {}
        ));       
        addItem(new WatchUi.MenuItem(
            "Display options",
            null,
            :displayOptions,
            {}
        ));
        addItem(new WatchUi.ToggleMenuItem(
            "Bulk entry",
            {:enabled => "On", :disabled => "Off"},
            :bulkEntry,
            Properties.getValue("bulkEntry") == true,
            {}
        ));

        addItem(new WatchUi.ToggleMenuItem(
            "Touch input",
            {:enabled => "On", :disabled => "Off"},
            :touchInput,
            Properties.getValue("touchInput") == true,
            {}
        ));
        addItem(new WatchUi.ToggleMenuItem(
            "Stats after hole",
            {:enabled => "On", :disabled => "Off"},
            :statsAfterHole,
            Properties.getValue("statsAfterHole") == true,
            {}
        ));
        addItem(new WatchUi.ToggleMenuItem(
            "Units",
            {:enabled => "Miles", :disabled => "Km"},
            :useImperial,
            Properties.getValue("useImperial") != false,
            {}
        ));
        addItem(new WatchUi.ToggleMenuItem(
            "Par",
            {:enabled => "Womens", :disabled => "Mens"},
            :womensParMode,
            Properties.getValue("womensParMode") == true,
            {}
        ));
        addItem(new WatchUi.ToggleMenuItem(
            "Auto swing detect",
            {:enabled => "On", :disabled => "Off"},
            :swingDetection,
            Properties.getValue("swingDetection") == true,
            {}
        ));
        addItem(new WatchUi.ToggleMenuItem(
            "Swing vibration",
            {:enabled => "On", :disabled => "Off"},
            :swingVibration,
            Properties.getValue("swingVibration") != false,
            {}
        ));
        addItem(new WatchUi.MenuItem(
            "Swing sensitivity",
            _getSensitivityLabel(),
            :swingDetectionSensitivity,
            {}
        ));
    }

    hidden function _getSensitivityLabel() {
        var v = Properties.getValue("swingDetectionSensitivity");
        if (v == 0) { return "Low"; }
        if (v == 2) { return "High"; }
        return "Medium";
    }
}

