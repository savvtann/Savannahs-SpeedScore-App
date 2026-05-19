using Toybox.WatchUi;
using Toybox.Application;

class MyCoursesDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _screenManager;
    hidden var _favs;

    function initialize(screenManager, favs) {
        Menu2InputDelegate.initialize();
        _screenManager = screenManager;
        _favs          = favs;
    }

    function onSelect(item) {
        var id = item.getId();
        if (id == :empty || !(id instanceof Number)) { return; }
        var course = _favs[id];
        var app = Application.getApp();
        app.setSelectedCourse(course["id"], course["name"]);
        WatchUi.pushView(new LoadingView("Loading teesets..."), new LoadingDelegate(), WatchUi.SLIDE_LEFT);
        app._apiClient.fetchTeesetsForCourse(course["id"], method(:onTeesetsLoaded));
    }

    function onTeesetsLoaded(teesets) {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        if (teesets != null && teesets.size() > 0) {
            Application.getApp()._roundFlowDepth++;
            WatchUi.pushView(
                new TeesetPickerView(teesets),
                new TeesetMenuDelegate(teesets),
                WatchUi.SLIDE_LEFT
            );
        } else {
            Application.getApp().startRound();
        }
    }

    function onHold(item) {
        var id = item.getId();
        if (id == :empty || !(id instanceof Number)) { return; }
        var course = _favs[id];
        var dialog = new WatchUi.Confirmation("Remove\n" + course["name"] + "?");
        WatchUi.pushView(
            dialog,
            new FavoriteConfirmDelegate(course["id"], course["name"], method(:onFavRemoved)),
            WatchUi.SLIDE_UP
        );
    }

    function onFavRemoved() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        var favs = Application.getApp().getSortedFavoriteCourses();
        WatchUi.pushView(
            new MyCoursesView(favs),
            new MyCoursesDelegate(_screenManager, favs),
            WatchUi.SLIDE_DOWN
        );
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
