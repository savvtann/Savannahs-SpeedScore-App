using Toybox.WatchUi;
using Toybox.Graphics;

class HistoricalRoundSummaryView extends WatchUi.View {
    hidden var _roundData;

    function initialize(roundData) {
        View.initialize();
        _roundData = roundData;
    }

    function onLayout(dc) {}
    function onShow()  {}
    function onHide()  {}

    function onUpdate(dc) {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var strokes = _roundData["strokes"];
        var timeSec = _roundData["time"];
        var teeset  = _roundData["teeset"];
        if (teeset == null || teeset.equals("")) {
            teeset = _roundData["roundType"];
        }
        if (strokes == null) { strokes = 0; }
        if (timeSec == null) { timeSec = 0; }
        if (teeset  == null) { teeset  = "-"; }

        var timeInt = timeSec.toNumber();
        var mins    = timeInt / 60;
        var secs    = timeInt % 60;
        var timeStr = mins.format("%02d") + ":" + secs.format("%02d");
        var speed   = strokes + mins;

        var dateStr  = _roundData["date"];
        if (dateStr == null) { dateStr = _roundData["createdAt"]; }
        var dateLabel = _formatDateLabel(dateStr);

        // Top bar: date
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.12, Graphics.FONT_XTINY, dateLabel,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Grid
        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(w * 0.12, h * 0.20, w * 0.88, h * 0.20);
        dc.drawLine(w * 0.06, h * 0.44, w * 0.94, h * 0.44);
        dc.drawLine(w * 0.06, h * 0.66, w * 0.94, h * 0.66);
        dc.drawLine(w * 0.12, h * 0.90, w * 0.88, h * 0.90);
        dc.drawLine(cx,       h * 0.20, cx,        h * 0.44);
        dc.drawLine(cx,       h * 0.66, cx,        h * 0.90);

        // Top-left: Strokes
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.275*w, h * 0.26, Graphics.FONT_XTINY, "Strokes",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.275*w, h * 0.36, Graphics.FONT_LARGE, strokes.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Top-right: Time
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.725*w, h * 0.26, Graphics.FONT_XTINY, "Time",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.725*w, h * 0.36, Graphics.FONT_MEDIUM, timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Center: Speed Score
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.52, Graphics.FONT_XTINY, "Speed Score",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x5DCAA5, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.60, Graphics.FONT_LARGE, speed.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom-left: Tee
        var teeDisplay = teeset.length() > 8 ? teeset.substring(0, 8) : teeset;
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.275*w, h * 0.72, Graphics.FONT_XTINY, "Type",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.275*w, h * 0.81, Graphics.FONT_XTINY, teeDisplay,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom-right: Holes
        var numHoles = _roundData["numHoles"];
        if (numHoles == null) { numHoles = "?"; }
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.725*w, h * 0.72, Graphics.FONT_XTINY, "Holes",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.725*w, h * 0.81, Graphics.FONT_MEDIUM, numHoles.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function _formatDateLabel(dateStr) {
        if (dateStr == null || dateStr.length() < 10) { return "Summary"; }
        var monthNames = ["Jan","Feb","Mar","Apr","May","Jun",
                          "Jul","Aug","Sep","Oct","Nov","Dec"];
        var m = 0; var d = 0; var y = 0;
        if (dateStr.substring(2, 3).equals("-")) {
            // MM-DD-YYYY
            m = dateStr.substring(0, 2).toNumber();
            d = dateStr.substring(3, 5).toNumber();
            y = dateStr.substring(6, 10).toNumber();
        } else {
            // YYYY-MM-DD
            y = dateStr.substring(0, 4).toNumber();
            m = dateStr.substring(5, 7).toNumber();
            d = dateStr.substring(8, 10).toNumber();
        }
        if (m == null || m < 1 || m > 12) { return dateStr.substring(0, 10); }
        if (d == null) { d = 0; }
        if (y == null) { y = 0; }
        return monthNames[m - 1] + " " + d.format("%02d") + " " + y.format("%04d");
    }
}
