using Toybox.WatchUi;
using Toybox.Application;

class CourseSearchDelegate extends WatchUi.TextPickerDelegate {
    function initialize() {
        TextPickerDelegate.initialize();
        System.println("SEARCH: delegate initialized");
    }

    function onTextEntered(text, changed) {
        System.println("SEARCH: onTextEntered text='" + text + "'");
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        if (text != null && text.length() > 0) {
            Application.getApp().searchCourse(text);
            System.println("SEARCH: fetch started");
        }
        return true;
    }

    function onCancel() {
        System.println("SEARCH: onCancel");
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
