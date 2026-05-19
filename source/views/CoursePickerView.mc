using Toybox.WatchUi;

class CoursePickerView extends WatchUi.Menu2 {
    hidden var _courses;

    function initialize(courses) {
        Menu2.initialize({:title => "Courses"});
        _courses = courses;

        addItem(new WatchUi.MenuItem("My Courses",      null,                 :myCourses, {}));
        addItem(new WatchUi.MenuItem("Search by name",  null,                 :search,    {}));
        addItem(new WatchUi.MenuItem("Practice round!", "no location needed", :practice,  {}));

        if (courses != null && courses.size() > 0) {
            addItem(new WatchUi.MenuItem("── Nearby ──", null, :header_nearby, {}));
            for (var i = 0; i < courses.size(); i++) {
                var name = courses[i]["name"];
                var dist = courses[i]["distanceKm"];
                if (dist == null) { dist = courses[i]["_dist"]; }
                var distStr = (dist != null) ? dist.format("%.1f") + " km" : null;
                addItem(new WatchUi.MenuItem(name, distStr, i, {}));
            }
        } else {
            addItem(new WatchUi.MenuItem("No courses found", "Tap to retry", :retry_nearby, {}));
        }
    }

    function getCourses() { return _courses; }
}