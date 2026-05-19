using Toybox.Sensor;
using Toybox.Timer;
using Toybox.Attention;
using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Math;
using Toybox.System;

class SwingDetector {
    hidden const STATE_SEARCHING = 0;
    hidden const STATE_STABLE    = 1;
    hidden const STATE_COOLDOWN  = 2;

    // Magnitude (milli-g) below which the player is considered at address.
    // Gravity alone = ~1000 milli-g. Running peaks 2000–3000+ milli-g.
    // STABILITY_CEILING is always used to EXIT the stable state (back to searching).
    // ENTRY_CEILING_HIGH is used only to ENTER the stable state on High sensitivity.
    hidden const STABILITY_CEILING    = 1400;
    hidden const ENTRY_CEILING_HIGH   = 1200; // High: must be fairly still to arm detector

    // How long the player must be stable before a swing can be detected.
    hidden const STABILITY_MS = 200;

    // Cooldown after a detected swing before the next one can register.
    hidden const COOLDOWN_MS = 2000;

    // Swing spike thresholds per sensitivity setting (0=Low, 1=Medium, 2=High)
    hidden const SWING_THRESHOLD_LOW  = 2500;
    hidden const SWING_THRESHOLD_MED  = 1800;
    hidden const SWING_THRESHOLD_HIGH = 1300; // catches putting strokes

    hidden var _state         = 0;
    hidden var _stableStartMs = -1; // System.getTimer() when stillness began
    hidden var _cooldownEndMs = -1; // System.getTimer() when cooldown ends
    hidden var _roundState    = null;
    hidden var _timer         = null;

    function initialize() {}

    function start() {
        _roundState    = Application.getApp().getRoundState();
        _state         = STATE_SEARCHING;
        _stableStartMs = -1;
        _cooldownEndMs = -1;

        // enableSensorEvents activates the IMU so Sensor.getInfo().accel
        // returns data. Without this call accel is null on most devices.
        try {
            Sensor.enableSensorEvents(method(:onSensorEvent));
            System.println("SwingDetector: sensor events enabled");
        } catch (ex) {
            System.println("SwingDetector: enableSensorEvents unavailable");
        }

        // 50 ms timer ensures consistent 20 Hz polling regardless of how
        // often enableSensorEvents fires on this device.
        _timer = new Timer.Timer();
        _timer.start(method(:onTick), 50, true);
        System.println("SwingDetector: started");
    }

    function stop() {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        try {
            Sensor.enableSensorEvents(null);
        } catch (ex) {}
        System.println("SwingDetector: stopped");
    }

    // Called by Sensor.enableSensorEvents — process data here directly so
    // detection works even if the timer and the sensor fire at different rates.
    function onSensorEvent(info) {
        if (info == null) { return; }
        _handleSensorInfo(info);
    }

    // Called by the 50 ms timer — ensures we poll at a known rate in case
    // enableSensorEvents fires slowly on this device.
    function onTick() {
        var info = Sensor.getInfo();
        if (info == null) { return; }
        _handleSensorInfo(info);
    }

    hidden function _handleSensorInfo(info) {
        if (!Application.getApp().isSwingDetectionEnabled()) { return; }
        if (_roundState == null || _roundState.isPaused)     { return; }

        var accel = info.accel;
        if (accel == null) { return; }

        var x = accel[0];
        var y = accel[1];
        var z = accel[2];
        if (x == null || y == null || z == null) { return; }

        _processSample(x, y, z);
    }

    hidden function _processSample(x, y, z) {
        var fx  = x.toFloat();
        var fy  = y.toFloat();
        var fz  = z.toFloat();
        var mag = Math.sqrt(fx*fx + fy*fy + fz*fz).toNumber();
        var now = System.getTimer();

        if (_state == STATE_COOLDOWN) {
            if (now >= _cooldownEndMs) {
                _state         = STATE_SEARCHING;
                _stableStartMs = -1;
                System.println("SwingDetector: cooldown done");
            }
            return;
        }

        if (_state == STATE_SEARCHING) {
            var entryCeiling = _getEntryCeiling();
            if (mag < entryCeiling) {
                if (_stableStartMs < 0) {
                    _stableStartMs = now;
                } else if ((now - _stableStartMs) >= STABILITY_MS) {
                    _state = STATE_STABLE;
                    System.println("SwingDetector: STABLE mag=" + mag);
                }
            } else {
                _stableStartMs = -1;
            }
            return;
        }

        // STATE_STABLE — watching for a swing spike.
        // Always use STABILITY_CEILING (1400) to exit so that a putt's gentle
        // backswing (which may exceed ENTRY_CEILING_HIGH) doesn't abort detection.
        var threshold = _getThreshold();
        if (mag >= threshold) {
            _swingDetected(now);
        } else if (mag >= STABILITY_CEILING) {
            // Clearly moving without swinging (e.g. adjusted stance, started running)
            _state         = STATE_SEARCHING;
            _stableStartMs = -1;
        }
    }

    hidden function _getEntryCeiling() {
        var s = Application.getApp().getSwingDetectionSensitivity();
        if (s == 2) { return ENTRY_CEILING_HIGH; }
        return STABILITY_CEILING;
    }

    hidden function _getThreshold() {
        var s = Application.getApp().getSwingDetectionSensitivity();
        if (s == 0) { return SWING_THRESHOLD_LOW; }
        if (s == 2) { return SWING_THRESHOLD_HIGH; }
        return SWING_THRESHOLD_MED;
    }

    hidden function _swingDetected(now) {
        System.println("SwingDetector: SWING DETECTED");
        _state         = STATE_COOLDOWN;
        _cooldownEndMs = now + COOLDOWN_MS;

        _roundState.addStroke();
        _roundState.autoSwingUntil = _roundState.elapsedSeconds + 3;

        if (Application.getApp().isSwingVibrationEnabled()) {
            Attention.vibrate([new Attention.VibeProfile(50, 300)]);
        }

        WatchUi.requestUpdate();
    }
}
