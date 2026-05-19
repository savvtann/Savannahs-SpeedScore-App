using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;

class StrokeEntryView extends BasePageView {
    hidden var _holeNumber;
    hidden var _strokes;
    hidden var _par;

    function initialize(holeNumber) {
        BasePageView.initialize();
        _holeNumber = holeNumber;
        _strokes    = 0;
        _par        = Application.getApp().getRoundState().getParForHole(holeNumber);
    }

    function onLayout(dc) { setLayout(Rez.Layouts.PrettyPage(dc)); }
    function onShow()  {}
    function onHide()  {}

    function addStroke()    { _strokes++; }
    function removeStroke() { if (_strokes > 0) { _strokes--; } }
    function getStrokes()   { return _strokes; }

    function onUpdate(dc) {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Top bar
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.15, Graphics.FONT_TINY,
            "Hole " + _holeNumber + " · Par " + _par,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Dividers
        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(w * 0.12, h * 0.22, w * 0.88, h * 0.22);
        dc.drawLine(w * 0.12, h * 0.78, w * 0.88, h * 0.78);

        // Label
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.35, Graphics.FONT_XTINY, "Strokes this hole",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Stroke count
        var diff        = _strokes - _par;
        var strokeColor = Graphics.COLOR_WHITE;
        if (_strokes > 0) {
            if (diff < 0)       { strokeColor = 0x5DCAA5; }
            else if (diff == 1) { strokeColor = 0xEF9F27; }
            else if (diff > 1)  { strokeColor = 0xF09595; }
        }
        dc.setColor(strokeColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.55, Graphics.FONT_NUMBER_HOT, _strokes.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}