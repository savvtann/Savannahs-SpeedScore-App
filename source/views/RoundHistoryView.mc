using Toybox.WatchUi;
using Toybox.Graphics;

// Shown while GET /rounds is in flight
class RoundHistoryLoadingView extends WatchUi.View {
    function initialize() { View.initialize(); }
    function onLayout(dc) {}
    function onShow()  {}
    function onHide()  {}

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2, dc.getHeight() / 2,
            Graphics.FONT_MEDIUM, "Loading...",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}

class RoundHistoryLoadingDelegate extends WatchUi.BehaviorDelegate {
    function initialize() { BehaviorDelegate.initialize(); }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

// Menu listing past rounds sorted newest-first (populated after API response)
class RoundHistoryView extends WatchUi.Menu2 {
    hidden var _rounds;

    function initialize(rounds) {
        Menu2.initialize({:title => "Round History"});
        _rounds = rounds;

        if (rounds == null || rounds.size() == 0) {
            addItem(new WatchUi.MenuItem("No rounds found", null, :none, {}));
            return;
        }

        var monthNames = ["Jan","Feb","Mar","Apr","May","Jun",
                          "Jul","Aug","Sep","Oct","Nov","Dec"];
        for (var i = 0; i < rounds.size(); i++) {
            var round  = rounds[i];
            var label  = _formatLabel(round, monthNames);
            var sub    = _formatSubtitle(round);
            addItem(new WatchUi.MenuItem(label, sub, i, {}));
        }
    }

    function getRounds() { return _rounds; }

    hidden function _extractDateStr(round) {
        var d = round["date"];
        if (d != null) { return d; }
        return round["createdAt"];
    }

    hidden function _formatLabel(round, monthNames) {
        var dateStr = _extractDateStr(round);
        var month   = 0;
        var day     = 0;
        if (dateStr != null && dateStr.length() >= 10) {
            // date field is MM-DD-YYYY (e.g. "02-19-2026")
            month = dateStr.substring(0, 2).toNumber();
            day   = dateStr.substring(3, 5).toNumber();
            if (month == null) { month = 0; }
            if (day   == null) { day   = 0; }
        }
        var monthName = (month >= 1 && month <= 12) ? monthNames[month - 1] : "???";
        var strokes   = round["strokes"];
        if (strokes == null) { strokes = 0; }
        return monthName + " " + day.format("%02d") + "  ·  " + strokes;
    }

    hidden function _formatSubtitle(round) {
        var holes = round["numHoles"];
        if (holes != null) { return holes + " holes"; }
        var teeset = round["teeset"];
        if (teeset != null && !teeset.equals("")) { return teeset; }
        return null;
    }
}
