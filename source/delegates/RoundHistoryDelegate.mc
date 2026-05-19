using Toybox.WatchUi;

class RoundHistoryDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _screenManager;
    hidden var _rounds;

    function initialize(screenManager, rounds) {
        Menu2InputDelegate.initialize();
        _screenManager = screenManager;
        _rounds        = rounds;
    }

    function onSelect(item) {
        var id = item.getId();
        if (id == :none) { return; }
        if (_rounds == null || !(id instanceof Number)) { return; }
        if (id < 0 || id >= _rounds.size()) { return; }

        var round = _rounds[id];
        WatchUi.pushView(
            new HistoricalRoundSummaryView(round),
            new HistoricalRoundSummaryDelegate(),
            WatchUi.SLIDE_LEFT
        );
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
