using Toybox.WatchUi;

class MyCoursesView extends WatchUi.Menu2 {
    function initialize(favs) {
        Menu2.initialize({:title => "My Courses"});

        if (favs == null || favs.size() == 0) {
            addItem(new WatchUi.MenuItem("No favorites yet", "Hold a course to add", :empty, {}));
            return;
        }

        for (var i = 0; i < favs.size(); i++) {
            addItem(new WatchUi.MenuItem(favs[i]["name"], "★", i, {}));
        }
    }
}
