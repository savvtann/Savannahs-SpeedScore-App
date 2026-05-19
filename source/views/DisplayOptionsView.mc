using Toybox.WatchUi;
using Toybox.Application.Properties;

class DisplayOptionsView extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title => "Display"});

        addItem(new WatchUi.ToggleMenuItem(
            "Hole number",
            {:enabled => "On", :disabled => "Off"},
            :showHoleNumber,
            Properties.getValue("showHoleNumber") != false,
            {}
        ));

        addItem(new WatchUi.ToggleMenuItem(
            "Par",
            {:enabled => "On", :disabled => "Off"},
            :showPar,
            Properties.getValue("showPar") != false,
            {}
        ));

        addItem(new WatchUi.ToggleMenuItem(
            "Strokes",
            {:enabled => "On", :disabled => "Off"},
            :showStrokes,
            Properties.getValue("showStrokes") != false,
            {}
        ));

        addItem(new WatchUi.ToggleMenuItem(
            "Round Timer",
            {:enabled => "On", :disabled => "Off"},
            :showRoundTimer,
            Properties.getValue("showRoundTimer") != false,
            {}
        ));

        addItem(new WatchUi.ToggleMenuItem(
            "Speed score",
            {:enabled => "On", :disabled => "Off"},
            :showSpeedScore,
            Properties.getValue("showSpeedScore") != false,
            {}
        ));

        addItem(new WatchUi.ToggleMenuItem(
            "Golf score",
            {:enabled => "On", :disabled => "Off"},
            :showGolfScore,
            Properties.getValue("showGolfScore") != false,
            {}
        ));

        addItem(new WatchUi.ToggleMenuItem(
            "Compass arrow",
            {:enabled => "On", :disabled => "Off"},
            :showArrow,
            Properties.getValue("showArrow") != false,
            {}
        ));

        addItem(new WatchUi.ToggleMenuItem(
            "Hole Timer",
            {:enabled => "On", :disabled => "Off"},
            :showHoleTimer,
            Properties.getValue("showHoleTimer") != false,
            {}
        ));
    }
}

class DisplayOptionsDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _screenManager;

    function initialize(screenManager) {
        Menu2InputDelegate.initialize();
        _screenManager = screenManager;
    }

    function onSelect(item) {
        var id      = item.getId();
        var enabled = item.isEnabled();

        if (id == :showHoleNumber) { Properties.setValue("showHoleNumber", enabled); }
        else if (id == :showPar)         { Properties.setValue("showPar",         enabled); }
        else if (id == :showStrokes)     { Properties.setValue("showStrokes",     enabled); }
        else if (id == :showRoundTimer) { Properties.setValue("showRoundTimer", enabled); }
        else if (id == :showHoleTimer)  { Properties.setValue("showHoleTimer",  enabled); }        else if (id == :showSpeedScore)  { Properties.setValue("showSpeedScore",  enabled); }
        else if (id == :showGolfScore)   { Properties.setValue("showGolfScore",   enabled); }
        else if (id == :showArrow)       { Properties.setValue("showArrow",       enabled); }

        System.println(id + ": " + enabled);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}