using Toybox.WatchUi;
using Toybox.Application;

class HomeView extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title => "SpeedScore"});
        addItem(new WatchUi.MenuItem("Start round",    null, :startRound,    {}));
        addItem(new WatchUi.MenuItem("My courses",    null, :myCourses,     {}));
        addItem(new WatchUi.MenuItem("Round history", null, :roundHistory,  {}));
        addItem(new WatchUi.MenuItem("Settings",      null, :settings,      {}));
    }
}