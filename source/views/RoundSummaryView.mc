using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;

class RoundSummaryView extends BasePageView {
    hidden var _roundState;
    hidden var _practiceMode;
    hidden var _page;

    function initialize() {
        View.initialize();
        _roundState   = Application.getApp().getRoundState();
        _practiceMode = Application.getApp().isPracticeMode();
        _page         = _roundState.getHoleData().size();
    }

    function onLayout(dc) { setLayout(Rez.Layouts.PrettyPage(dc)); }
    function onShow()  {}
    function onHide()  {}

    function nextPage() {
        var holeData = _roundState.getHoleData();
        var total    = holeData.size() + 1;
        _page        = (_page + 1) % total;
        WatchUi.requestUpdate();
    }

    function prevPage() {
        var holeData = _roundState.getHoleData();
        var total    = holeData.size() + 1;
        _page        = (_page - 1 + total) % total;
        WatchUi.requestUpdate();
    }

    function isOnTotalsPage() {
        return _page >= _roundState.getHoleData().size();
    }

    function onUpdate(dc) {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var holeData = _roundState.getHoleData();

        if (_page >= holeData.size()) {
            _drawTotalsPage(dc, w, h, cx);
            return;
        }

        // ── HOLE PAGE ─────────────────────────────────────────
        var hole           = holeData[_page];
        var holeNum        = hole["number"];
        var strokes        = hole["strokes"];
        var timeSec        = hole["time"];
        var par            = _roundState.getParForHole(holeNum);
        var diff           = strokes - par;
        var mins           = timeSec / 60;
        var secs           = timeSec % 60;
        var timeStr        = mins.format("%02d") + ":" + secs.format("%02d");
        var holeSpeedScore = strokes + mins;

        var diffColor = Graphics.COLOR_WHITE;
        if (diff < 0)       { diffColor = 0x5DCAA5; }
        else if (diff == 1) { diffColor = 0xEF9F27; }
        else if (diff > 1)  { diffColor = 0xF09595; }

        // Top bar: hole / page indicator
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.12, Graphics.FONT_XTINY,
            "Hole " + holeNum + " · Par " + par,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Page indicator
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.95, Graphics.FONT_XTINY,
            (_page + 1).toString() + " / " + holeData.size(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Grid lines
        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(w * 0.12, h * 0.20, w * 0.88, h * 0.20);
        dc.drawLine(w * 0.06, h * 0.44, w * 0.94, h * 0.44);
        dc.drawLine(w * 0.06, h * 0.66, w * 0.94, h * 0.66);
        dc.drawLine(w * 0.12, h * 0.90, w * 0.88, h * 0.90);
        dc.drawLine(cx, h * 0.20, cx, h * 0.44);
        dc.drawLine(cx, h * 0.66, cx, h * 0.90);

        // Top left: Strokes
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.275*w, h * 0.26, Graphics.FONT_XTINY, "Strokes",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(diffColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.275*w, h * 0.36, Graphics.FONT_LARGE, strokes.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Top right: Time
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.725*w, h * 0.26, Graphics.FONT_XTINY, "Time",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.725*w, h * 0.36, Graphics.FONT_MEDIUM, timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Center: Speed score
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.52, Graphics.FONT_XTINY, "Speed Score",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(diffColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.60, Graphics.FONT_LARGE, holeSpeedScore.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom left: vs Par
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.275*w, h * 0.72, Graphics.FONT_XTINY, "vs Par",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var diffStr = diff == 0 ? "E" : (diff > 0 ? "+" + diff : diff.toString());
        dc.setColor(diffColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.275*w, h * 0.81, Graphics.FONT_MEDIUM, diffStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom right: Hole number
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.725*w, h * 0.72, Graphics.FONT_XTINY, "Hole",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.725*w, h * 0.81, Graphics.FONT_MEDIUM, holeNum.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function _drawTotalsPage(dc, w, h, cx) {
        // Top bar
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.12, Graphics.FONT_XTINY, "Round Complete",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Grid lines
        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(w * 0.12, h * 0.20, w * 0.88, h * 0.20);
        dc.drawLine(w * 0.06, h * 0.44, w * 0.94, h * 0.44);
        dc.drawLine(w * 0.06, h * 0.66, w * 0.94, h * 0.66);
        dc.drawLine(w * 0.12, h * 0.90, w * 0.88, h * 0.90);
        dc.drawLine(cx, h * 0.20, cx, h * 0.44);
        dc.drawLine(cx, h * 0.66, cx, h * 0.90);

        // Top left: Strokes
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.275*w, h * 0.26, Graphics.FONT_XTINY, "Strokes",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.275*w, h * 0.36, Graphics.FONT_LARGE, _roundState.strokeCount.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Top right: Time
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.725*w, h * 0.26, Graphics.FONT_XTINY, "Time",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.725*w, h * 0.36, Graphics.FONT_MEDIUM, _roundState.getFormattedTime(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Center: Speed score
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.52, Graphics.FONT_XTINY, "Speed Score",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x5DCAA5, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.60, Graphics.FONT_LARGE, _roundState.getSpeedScore().toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom left: vs Par
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.275*w, h * 0.72, Graphics.FONT_XTINY, "vs Par",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var parDiff      = _roundState.getParDiff();
        var parDiffColor = Graphics.COLOR_WHITE;
        if (parDiff.equals("E"))                     { parDiffColor = 0x888888; }
        else if (parDiff.substring(0,1).equals("-")) { parDiffColor = 0x5DCAA5; }
        else                                         { parDiffColor = 0xF09595; }
        dc.setColor(parDiffColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.275*w, h * 0.81, Graphics.FONT_MEDIUM, parDiff,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom right: POST or PRACTICE
        if (_practiceMode) {
            dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0.725*w, h * 0.76, Graphics.FONT_XTINY, "Practice",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(0.725*w, h * 0.84, Graphics.FONT_XTINY, "not saved",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.setColor(0x5DCAA5, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0.725*w, h * 0.72, Graphics.FONT_XTINY, "Post",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0.725*w, h * 0.81, Graphics.FONT_XTINY, "START",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}