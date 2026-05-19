using Toybox.WatchUi;

class HoleJumperDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _roundState;

    function initialize(roundState) {
        Menu2InputDelegate.initialize();
        _roundState = roundState;
    }

    function onSelect(item) {
        _roundState.holeNumber = item.getId();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.requestUpdate();
    }

    function onBack() {
        // Leave holeNumber as set by advanceHole (sequential next)
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.requestUpdate();
    }
}
