using Toybox.WatchUi;
using Toybox.Application;

class CoursePickerDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _screenManager;
    hidden var _courses;
    hidden var _allCourses;

    function initialize(screenManager, courses) {
        Menu2InputDelegate.initialize();
        _screenManager = screenManager;
        _courses       = courses;
        _allCourses    = courses;
    }

    function onSelect(item) {
        var id = item.getId();

        // Ignore header items
        if (id == :header_nearby || id == :none) {
            return;
        }

        // My Courses
        if (id == :myCourses) {
            var favs = Application.getApp().getSortedFavoriteCourses();
            WatchUi.pushView(
                new MyCoursesView(favs),
                new MyCoursesDelegate(_screenManager, favs),
                WatchUi.SLIDE_LEFT
            );
            return;
        }

        // Retry nearby search
        if (id == :retry_nearby) {
            Application.getApp()._apiClient.fetchNearbyCourses(method(:onCoursesReloaded));
            return;
        }

        // Practice round — pick a start hole first
        if (id == :practice) {
            var app = Application.getApp();
            app.setSelectedCourse("practice", "Practice Round");
            WatchUi.pushView(
                new HolePickerView(18),
                new HolePickerDelegate("practice", "Practice", null),
                WatchUi.SLIDE_LEFT
            );
            return;
        }

        // Search by name
        if (id == :search) {
            if (WatchUi has :TextPicker) {
                var picker = new WatchUi.TextPicker("");
                WatchUi.pushView(picker, new CourseSearchDelegate(), WatchUi.SLIDE_UP);
            } else {
                Application.getApp()._apiClient.fetchAllCoursesForSearch(method(:onAllCoursesLoaded));
            }
            return;
        }

        // Nearby course (identified by numeric id)
        if (_courses != null && _courses.size() > 0 && id instanceof Number) {
            var course = _courses[id];
            if (course != null) {
                _showCourseActions(course);
            }
        }
    }

    hidden function _showCourseActions(course) {
        var app   = Application.getApp();
        var isFav = app.isFavoriteCourse(course["id"]);
        var menu  = new WatchUi.Menu2({:title => course["name"]});
        menu.addItem(new WatchUi.MenuItem("Start Round",           null, :startRound, {}));
        if (isFav) {
            menu.addItem(new WatchUi.MenuItem("Remove from My Courses", "★",   :toggleFav, {}));
        } else {
            menu.addItem(new WatchUi.MenuItem("Add to My Courses",      null,  :toggleFav, {}));
        }
        WatchUi.pushView(menu, new CourseActionDelegate(course, _screenManager, _courses, method(:_selectCourse)), WatchUi.SLIDE_UP);
    }

    function onHold(item) {
        var id = item.getId();
        System.println("HOLD: onHold triggered, id=" + id);
        if (!(id instanceof Number)) { return; }
        if (_courses == null || _courses.size() <= id) { return; }

        var course   = _courses[id];
        var courseId = course["id"];
        var name     = course["name"];
        System.println("HOLD: showing confirmation for " + name);
        var app      = Application.getApp();
        var prompt   = app.isFavoriteCourse(courseId) ? "Remove\n" + name + "?" : "Favorite\n" + name + "?";
        var dialog   = new WatchUi.Confirmation(prompt);
        WatchUi.pushView(
            dialog,
            new FavoriteConfirmDelegate(courseId, name, method(:onFavToggled)),
            WatchUi.SLIDE_UP
        );
    }

    function onFavToggled() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.pushView(
            new CoursePickerView(_courses),
            new CoursePickerDelegate(_screenManager, _courses),
            WatchUi.SLIDE_DOWN
        );
    }

    // Called after retrying nearby courses (if you ever re‑enable retry)
    function onCoursesReloaded(newCourses) {
        if (newCourses == null) {
            newCourses = [];
        }
        WatchUi.switchToView(
            new CoursePickerView(newCourses),
            new CoursePickerDelegate(_screenManager, newCourses),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    hidden function _selectCourse(courseId, name) {
        var app = Application.getApp();
        app.setSelectedCourse(courseId, name);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        app._apiClient.fetchCompactCourse(name, method(:onCompactCourseLoaded));
    }

    function onCompactCourseLoaded(teeset) {
        Application.getApp().startRound();
    }

    function onAllCoursesLoaded(courses) {
        if (courses == null || courses.size() == 0) {
            if (WatchUi has :showToast) { WatchUi.showToast({:text => "No courses found"}); }
            return;
        }
        WatchUi.pushView(
            new CoursePickerView(courses),
            new CoursePickerDelegate(_screenManager, courses),
            WatchUi.SLIDE_LEFT
        );
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}