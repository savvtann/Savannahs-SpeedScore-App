using Toybox.WatchUi;
using Toybox.Application;

class FavoriteConfirmDelegate extends WatchUi.ConfirmationDelegate {
    hidden var _courseId;
    hidden var _courseName;
    hidden var _onDone;

    function initialize(courseId, courseName, onDone) {
        ConfirmationDelegate.initialize();
        _courseId   = courseId;
        _courseName = courseName;
        _onDone     = onDone;
    }

    function onResponse(response) {
        if (response == WatchUi.CONFIRM_YES) {
            Application.getApp().toggleFavoriteCourse(_courseId, _courseName);
            if (_onDone != null) {
                _onDone.invoke();
            }
        }
    }
}
