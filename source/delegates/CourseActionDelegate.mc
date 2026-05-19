using Toybox.WatchUi;
using Toybox.Application;

// Handles the "Start Round / Add to My Courses" sub-menu that appears when a
// user taps a nearby or search-result course. _onStartRound is a method
// reference supplied by the calling delegate so each context keeps its own
// round-start logic. _courses is non-null when coming from CoursePickerView
// (so we can reload it after a favorite toggle), null for search context.
class CourseActionDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _course;
    hidden var _screenManager;
    hidden var _courses;
    hidden var _onStartRound;

    function initialize(course, screenManager, courses, onStartRound) {
        Menu2InputDelegate.initialize();
        _course       = course;
        _screenManager = screenManager;
        _courses      = courses;
        _onStartRound = onStartRound;
    }

    function onSelect(item) {
        var id = item.getId();
        if (id == :startRound) {
            _onStartRound.invoke(_course["id"], _course["name"]);
        } else if (id == :toggleFav) {
            var app    = Application.getApp();
            var prompt = app.isFavoriteCourse(_course["id"])
                ? "Remove\n" + _course["name"] + "?"
                : "Favorite\n" + _course["name"] + "?";
            WatchUi.pushView(
                new WatchUi.Confirmation(prompt),
                new FavoriteConfirmDelegate(_course["id"], _course["name"], method(:onFavToggled)),
                WatchUi.SLIDE_UP
            );
        }
    }

    // Called by FavoriteConfirmDelegate after the toggle (Confirmation already
    // auto-popped, so ActionMenu is the current top of the stack).
    function onFavToggled() {
        WatchUi.popView(WatchUi.SLIDE_DOWN); // dismiss ActionMenu
        if (_courses != null) {
            // CoursePicker context: replace old picker with a fresh one
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.pushView(
                new CoursePickerView(_courses),
                new CoursePickerDelegate(_screenManager, _courses),
                WatchUi.SLIDE_DOWN
            );
        }
        // Search context: Confirmation dismissed, ActionMenu popped — user returns to results
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
