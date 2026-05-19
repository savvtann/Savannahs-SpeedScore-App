using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;

class HoleDetailsView extends WatchUi.View {
    hidden var _scrollIndex = 0;

    function initialize() { View.initialize(); }
    function onLayout(dc) {setLayout(Rez.Layouts.PrettyPage(dc));}

    function onUpdate(dc) {
        var state    = Application.getApp().getRoundState();
        var holeData = state.getHoleData();
        var w        = dc.getWidth();
        var h        = dc.getHeight();

        View.onUpdate(dc);
        
        if (holeData.size() == 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w/2, h/2, Graphics.FONT_MEDIUM, "No holes yet", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        // Header
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w/2, 30, Graphics.FONT_TINY, "Hole " + (_scrollIndex + 1) + " of " + holeData.size(), Graphics.TEXT_JUSTIFY_CENTER);

        var hole    = holeData[_scrollIndex];
        var strokes = hole["strokes"];
        var time    = hole["time"];
        var mins    = time / 60;
        var secs    = time % 60;
        var timeStr = mins.format("%02d") + ":" + secs.format("%02d");
        var holeScore = strokes + mins;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w/2, 80,  Graphics.FONT_LARGE,  "Hole " + hole["number"], Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w/2, 160, Graphics.FONT_MEDIUM, "Time: " + timeStr, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w/2, 210, Graphics.FONT_MEDIUM, "Strokes: " + strokes, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w/2, 270, Graphics.FONT_MEDIUM, "Score: " + holeScore, Graphics.TEXT_JUSTIFY_CENTER);

    }

    function scrollUp() {
        if (_scrollIndex > 0) { _scrollIndex--; }
    }

    function scrollDown() {
        var size = Application.getApp().getRoundState().getHoleData().size();
        if (_scrollIndex < size - 1) { _scrollIndex++; }
    }
}

class HoleDetailsDelegate extends WatchUi.BehaviorDelegate {
    hidden var _screenManager;

    function initialize(screenManager) {
        BehaviorDelegate.initialize();
        _screenManager = screenManager;
    }

    function onKey(keyEvent) {
        var key  = keyEvent.getKey();
        var view = WatchUi.getCurrentView()[0];

        if (key == WatchUi.KEY_UP) {
            if (view instanceof HoleDetailsView) { view.scrollUp(); }
            WatchUi.requestUpdate();
            return true;
        }
        if (key == WatchUi.KEY_DOWN) {
            if (view instanceof HoleDetailsView) { view.scrollDown(); }
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    function onBack() {
        _screenManager.goToActiveHole();
        return true;
    }
}