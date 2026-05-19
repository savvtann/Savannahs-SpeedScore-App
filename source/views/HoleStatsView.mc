using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Timer;
using Toybox.Application;

class HoleStatsView extends WatchUi.View {
    hidden var _roundState;
    hidden var _screenManager;
    hidden var _timer;

    function initialize(roundState, durationMs, screenManager) {
        View.initialize();
        _roundState    = roundState;
        _screenManager = screenManager;
        _roundState.pause();
        _timer         = new Timer.Timer();
        _timer.start(method(:onDismiss), durationMs, false);
    }

    function onDismiss() {
        _timer.stop();
        _roundState.resume();
        _screenManager.goToActiveHole();
    }

    function onHide() {
        if (_timer != null) { _timer.stop(); }
    }

    function onUpdate(dc) {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.12, Graphics.FONT_XTINY,
            "Hole " + (_roundState.holeNumber - 1) + " complete",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(w * 0.12, h * 0.20, w * 0.88, h * 0.20);

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.32, Graphics.FONT_XTINY, "Score vs Par",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var parDiff  = _roundState.getParDiff();
        var parColor = parDiff.substring(0,1).equals("-") ? 0x5DCAA5 : (parDiff.equals("E") ? 0x888888 : 0xF09595);
        dc.setColor(parColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.42, Graphics.FONT_LARGE, parDiff,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.56, Graphics.FONT_XTINY, "Round Time",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.66, Graphics.FONT_MEDIUM, _roundState.getFormattedTime(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.78, Graphics.FONT_XTINY, "Speed Score",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x5DCAA5, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.87, Graphics.FONT_MEDIUM, _roundState.getSpeedScore().format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
