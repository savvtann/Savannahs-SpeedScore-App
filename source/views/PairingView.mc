using Toybox.WatchUi;
using Toybox.Graphics;

class PairingView extends WatchUi.View {
    hidden var _code;
    hidden var _dotCount;

    function initialize(code) {
        View.initialize();
        _code = code;
        _dotCount = 0;
    }

    function setCode(code) {
        _code = code;
        _dotCount = 0;
    }

    function advanceDot() {
        _dotCount = (_dotCount + 1) % 4;
    }

    function onLayout(dc) {}
    function onShow() {}
    function onHide() {}

    function onUpdate(dc) {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.12, Graphics.FONT_XTINY, "Link Watch",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.28, Graphics.FONT_XTINY, "Go to speedscore.org",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, h * 0.36, Graphics.FONT_XTINY, "and enter code:",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var code = _code != null ? _code : "------";
        dc.setColor(0x5DCAA5, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.56, Graphics.FONT_LARGE, code,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var dots = "";
        for (var i = 0; i < _dotCount; i++) { dots = dots + "."; }
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.80, Graphics.FONT_XTINY, dots,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
