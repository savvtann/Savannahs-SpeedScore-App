using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Sensor;
using Toybox.Activity;
using Toybox.System;

class InfoView extends WatchUi.View {
    hidden var _roundState;
    hidden var _page;

    hidden const PAGE_STATS     = 0;
    hidden const PAGE_TIME      = 1;
    hidden const PAGE_PROJECTED = 2;
    hidden const PAGE_PACE      = 3;
    hidden const PAGE_HR        = 4;
    hidden const PAGE_COUNT     = 5;

    function initialize(roundState) {
        View.initialize();
        _roundState = roundState;
        _page       = PAGE_STATS;
    }

    function nextPage() {
        _page = (_page + 1) % PAGE_COUNT;
        WatchUi.requestUpdate();
    }

    function prevPage() {
        _page = (_page - 1 + PAGE_COUNT) % PAGE_COUNT;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Page indicator dots
        for (var i = 0; i < PAGE_COUNT; i++) {
            var dotX = cx - (PAGE_COUNT * 12 / 2) + i * 12;
            if (i == _page) {
                dc.setColor(0x7FA3DF, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, h * 0.94, 4);
            } else {
                dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, h * 0.94, 3);
            }
        }

        switch (_page) {
            case PAGE_STATS:     _drawStats(dc, w, h, cx);     break;
            case PAGE_TIME:      _drawTime(dc, w, h, cx);      break;
            case PAGE_PROJECTED: _drawProjected(dc, w, h, cx); break;
            case PAGE_PACE:      _drawPace(dc, w, h, cx);      break;
            case PAGE_HR:        _drawHR(dc, w, h, cx);        break;
        }
    }

    hidden function _drawStats(dc, w, h, cx) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.12, Graphics.FONT_XTINY,
            "Stats through hole " + _roundState.holeNumber,
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

    hidden function _drawTime(dc, w, h, cx) {
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.12, Graphics.FONT_XTINY, "Time of Day",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(w * 0.12, h * 0.20, w * 0.88, h * 0.20);

        var now    = System.getClockTime();
        var hour   = now.hour;
        var min    = now.min;
        var ampm   = hour >= 12 ? "PM" : "AM";
        if (hour > 12) { hour = hour - 12; }
        if (hour == 0) { hour = 12; }
        var timeStr = hour.toString() + ":" + min.format("%02d") + " " + ampm;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.46, Graphics.FONT_LARGE, timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var info = Toybox.Time.Gregorian.info(Toybox.Time.now(), Toybox.Time.FORMAT_MEDIUM);
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.62, Graphics.FONT_SMALL,
            info.month + " " + info.day + ", " + info.year,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function _drawProjected(dc, w, h, cx) {
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.12, Graphics.FONT_XTINY, "Projected Finish",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(w * 0.12, h * 0.20, w * 0.88, h * 0.20);

        var holesPlayed = _roundState.holeNumber;
        var holesLeft   = _roundState.totalHoles - holesPlayed;
        var avgStrokes  = holesPlayed > 0 ? _roundState.strokeCount / holesPlayed : 0;
        var avgSecs     = holesPlayed > 0 ? _roundState.elapsedSeconds / holesPlayed : 0;
        var projStrokes = (_roundState.strokeCount + avgStrokes * holesLeft).toNumber();
        var projSecs    = (_roundState.elapsedSeconds + avgSecs * holesLeft).toNumber();
        var projMins    = projSecs / 60;
        var projRemSecs = projSecs % 60;
        var projTimeStr = projMins.format("%02d") + ":" + projRemSecs.format("%02d");
        var projSpeed   = projStrokes + projMins;

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.28, Graphics.FONT_XTINY, "Projected Score",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.38, Graphics.FONT_LARGE, projStrokes.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.52, Graphics.FONT_XTINY, "Projected Time",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.62, Graphics.FONT_MEDIUM, projTimeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.74, Graphics.FONT_XTINY, "Projected Speed",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x5DCAA5, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.84, Graphics.FONT_MEDIUM, projSpeed.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function _drawPace(dc, w, h, cx) {
        var isImperial = Application.getApp().useImperial();
        var unit       = isImperial ? "mph" : "km/h";

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.12, Graphics.FONT_XTINY, "Running Speed",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(w * 0.12, h * 0.20, w * 0.88, h * 0.20);

        var currentSpeed = "--";
        var avgSpeed     = "--";

        var sensorInfo = Sensor.getInfo();
        if (sensorInfo != null && (sensorInfo has :speed) && sensorInfo.speed != null) {
            var mps  = sensorInfo.speed.toFloat();
            var conv = isImperial ? mps * 2.23694 : mps * 3.6;
            currentSpeed = conv.format("%.1f");
        }

        var actInfo = Activity.getActivityInfo();
        if (actInfo != null && actInfo.averageSpeed != null) {
            var mps  = actInfo.averageSpeed.toFloat();
            var conv = isImperial ? mps * 2.23694 : mps * 3.6;
            avgSpeed = conv.format("%.1f");
        }

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.30, Graphics.FONT_XTINY, "Current",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.42, Graphics.FONT_LARGE, currentSpeed,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.52, Graphics.FONT_XTINY, unit,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.64, Graphics.FONT_XTINY, "Average",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.76, Graphics.FONT_MEDIUM, avgSpeed,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.84, Graphics.FONT_XTINY, unit,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function _drawHR(dc, w, h, cx) {
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.12, Graphics.FONT_XTINY, "Heart Rate",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(w * 0.12, h * 0.20, w * 0.88, h * 0.20);

        var info      = Sensor.getInfo();
        var currentHR = "--";
        var avgHR     = "--";

        if (info != null && (info has :heartRate) && info.heartRate != null) {
            currentHR = info.heartRate.toString();
        }

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.30, Graphics.FONT_XTINY, "Current",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0xF09595, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.42, Graphics.FONT_LARGE, currentHR,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.52, Graphics.FONT_XTINY, "bpm",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.64, Graphics.FONT_XTINY, "Average",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.76, Graphics.FONT_MEDIUM, avgHR,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.84, Graphics.FONT_XTINY, "bpm",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}