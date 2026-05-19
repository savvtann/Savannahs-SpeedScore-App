using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class ScreenManager {
    hidden var _currentView;
    hidden var _currentDelegate;
    hidden var _initialView;
    hidden var _initialDelegate;
    
    function initialize() {
        _initialView     = new HomeView();
        _currentView     = _initialView;
        _initialDelegate = new HomeDelegate(self);
        _currentDelegate = _initialDelegate;
    }
    
    // Switch between pages. Returns true if view changed, false otherwise.
    function switchView(key) {
        return false;
    }
    function getCurrentView() {
        return _currentView;
    }

    function getCurrentDelegate() {
        return _currentDelegate;
    }

    function getInitialView() {
        return _initialView;
    }

    function getInitialDelegate() {
        return _initialDelegate;
    }

    function startRound() {
        var app = Application.getApp();
        app._roundState = new RoundState();
        app.startTimer();
        app.startPositioning();
        app.startSwingDetector();

        var newView = new ActiveHoleView();
        var newDelegate;
        if (app.isTouchInputMode()) {
            newDelegate = new ActiveHoleTouchDelegate(self);
        } else {
            newDelegate = new ActiveHoleDelegate(self);
        }
        _currentView     = newView;
        _currentDelegate = newDelegate;
        Ui.switchToView(newView, newDelegate, Ui.SLIDE_LEFT);
    }

    function goToLoading() {
        Application.getApp()._roundFlowDepth = 0;
        var newView      = new HomeView();
        var newDelegate  = new HomeDelegate(self);
        _currentView     = newView;
        _currentDelegate = newDelegate;
        WatchUi.switchToView(newView, newDelegate, WatchUi.SLIDE_RIGHT);
    }

    function goToRoundSummary() {
        Application.getApp().stopSwingDetector();
        var newView      = new RoundSummaryView();
        var newDelegate  = new RoundSummaryDelegate(self, newView);
        _currentView     = newView;
        _currentDelegate = newDelegate;
        WatchUi.switchToView(newView, newDelegate, WatchUi.SLIDE_LEFT);
    }

    function goToSettings() {
        WatchUi.pushView(new SettingsView(), new SettingsDelegate(self), WatchUi.SLIDE_UP);
    }

    function goToStrokeEntry(holeNumber) {
        var newView      = new StrokeEntryView(holeNumber);
        var newDelegate  = new StrokeEntryDelegate(self, holeNumber, newView);
        _currentView     = newView;
        _currentDelegate = newDelegate;
        Ui.switchToView(newView, newDelegate, Ui.SLIDE_LEFT);
    }

    function goToActiveHole() {
        var app         = Application.getApp();
        var newView     = new ActiveHoleView();
        var newDelegate = app.isTouchInputMode()
            ? new ActiveHoleTouchDelegate(self)
            : new ActiveHoleDelegate(self);
        _currentView     = newView;
        _currentDelegate = newDelegate;
        Ui.switchToView(newView, newDelegate, Ui.SLIDE_RIGHT);
    }

    function goToHoleStats(roundState, durationMs) {
        var newView      = new HoleStatsView(roundState, durationMs, self);
        var newDelegate  = new HoleStatsDelegate(self, roundState);
        _currentView     = newView;
        _currentDelegate = newDelegate;
        Ui.switchToView(newView, newDelegate, Ui.SLIDE_UP);
    }
}