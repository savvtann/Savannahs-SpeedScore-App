// BasePageView.mc
using Toybox.WatchUi;

class BasePageView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    // Default implementation – override in subclasses
    function onKey(keyEvent) {
        return false; // key not handled
    }
}