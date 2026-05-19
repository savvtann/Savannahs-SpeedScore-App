using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;

class FinishView extends BasePageView {
    function initialize() { View.initialize(); }
    function onLayout(dc) {
        setLayout(Rez.Layouts.FinishPage(dc));
    }

    function onUpdate(dc) {
        var state = Application.getApp().getRoundState();
        var w = dc.getWidth();
        var h = dc.getHeight();

        // Draw background via layout first
        View.onUpdate(dc);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w/7, 135, Graphics.FONT_MEDIUM, "Time: " + state.getFormattedTime(), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(w/7, 200, Graphics.FONT_MEDIUM, "Strokes: " + state.strokeCount, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(w/7, 265, Graphics.FONT_MEDIUM, "Score: " + state.getSpeedScore().format("%d"), Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var uploadIcon = WatchUi.loadResource(Rez.Drawables.UploadIcon);
        var discardIcon = WatchUi.loadResource(Rez.Drawables.DiscardIcon);
        dc.drawBitmap(4*w/5,  h/3 - uploadIcon.getHeight()/2, uploadIcon);
        dc.drawBitmap(4*w/5, 2*h/3 - discardIcon.getHeight()/2, discardIcon);
    }
}

class FinishDelegate extends WatchUi.BehaviorDelegate {
    hidden var _screenManager;
    hidden var _keyEnterTime = null;
    hidden const HOLD_THRESHOLD = 600;

    function initialize(screenManager) {
        BehaviorDelegate.initialize();
        _screenManager = screenManager;
    }

    function onKeyPressed(keyEvent) {
        if (keyEvent.getKey() == WatchUi.KEY_ENTER) {
            _keyEnterTime = System.getTimer();
        }
        return false;
    }

    function onKeyReleased(keyEvent) {
        if (keyEvent.getKey() == WatchUi.KEY_ENTER) {
            Application.getApp().getApiClient().postRound(Application.getApp().getRoundState());
            Application.getApp().resetRound();
            return true;
        }
        return false;
    }

    function onBack() {
        System.println("Round discarded");
        Application.getApp().resetRound();
        return true;
    }
}