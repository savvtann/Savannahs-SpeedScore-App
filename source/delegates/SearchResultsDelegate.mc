using Toybox.WatchUi;
using Toybox.Application;

class SearchResultsDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _results;

    function initialize(results) {
        Menu2InputDelegate.initialize();
        _results = results;
    }

    function onSelect(item) {
        var id = item.getId();
        if (id == :none || !(id instanceof Number) || _results == null || id >= _results.size()) {
            return;
        }
        var course = _results[id];
        var app    = Application.getApp();
        var isFav  = app.isFavoriteCourse(course["id"]);
        var menu   = new WatchUi.Menu2({:title => course["name"]});
        menu.addItem(new WatchUi.MenuItem("Start Round",           null, :startRound, {}));
        if (isFav) {
            menu.addItem(new WatchUi.MenuItem("Remove from My Courses", "★",  :toggleFav, {}));
        } else {
            menu.addItem(new WatchUi.MenuItem("Add to My Courses",      null, :toggleFav, {}));
        }
        WatchUi.pushView(menu, new CourseActionDelegate(course, null, null, method(:_startRound)), WatchUi.SLIDE_UP);
    }

    function _startRound(courseId, name) {
        var app = Application.getApp();
        app.setSelectedCourse(courseId, name);
        WatchUi.popView(WatchUi.SLIDE_DOWN);  // dismiss action menu
        WatchUi.pushView(new LoadingView("Loading teesets..."), new LoadingDelegate(), WatchUi.SLIDE_LEFT);
        app._apiClient.fetchTeesetsForCourse(courseId, method(:onTeesetsLoaded));
    }

    function onTeesetsLoaded(teesets) {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        if (teesets != null && teesets.size() > 0) {
            Application.getApp()._roundFlowDepth++;
            WatchUi.pushView(
                new TeesetPickerView(teesets),
                new TeesetMenuDelegate(teesets),
                WatchUi.SLIDE_LEFT
            );
        } else {
            System.println("TEESETS: none found, starting round without teeset");
            Application.getApp().startRound();
        }
    }

    function onHold(item) {
        var id = item.getId();
        System.println("HOLD: onHold triggered in SearchResults, id=" + id);
        if (id == :none || !(id instanceof Number) || _results == null || id >= _results.size()) { return; }
        var course = _results[id];
        System.println("HOLD: showing confirmation for " + course["name"]);
        var app    = Application.getApp();
        var prompt = app.isFavoriteCourse(course["id"]) ? "Remove\n" + course["name"] + "?" : "Favorite\n" + course["name"] + "?";
        var dialog = new WatchUi.Confirmation(prompt);
        WatchUi.pushView(
            dialog,
            new FavoriteConfirmDelegate(course["id"], course["name"], method(:onFavToggled)),
            WatchUi.SLIDE_UP
        );
    }

    function onFavToggled() {
        System.println("SEARCH: fav toggled");
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
