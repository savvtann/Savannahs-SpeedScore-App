using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Math;

class ActiveHoleView extends BasePageView {

    function initialize() {
        BasePageView.initialize();
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.PrettyPage(dc));
    }

    function onShow() {}
    function onHide() {}

    function onUpdate(dc) {
        var app      = Application.getApp();
        var state    = app.getRoundState();
        var postHoleEntryMode = app.isPostHoleEntryMode();
        var w        = dc.getWidth();
        var h        = dc.getHeight();

        View.onUpdate(dc);

        // Old design mode
        //_drawFullMode(dc, state, postHoleEntryMode, w, h);

        // New grid design mode
        _drawGridMode(dc, state, postHoleEntryMode, w, h);

        // === PAUSED OVERLAY === (same for both modes)
        if (state.isPaused) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            for (var y = 0; y < h; y += 4) { dc.drawLine(0, y, w, y); }
            for (var x = 0; x < w; x += 4) { dc.drawLine(x, 0, x, h); }
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w/2, h/3 - 30, Graphics.FONT_LARGE, "PAUSED", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    hidden function _drawFullMode(dc, state, postHoleEntryMode, w, h) {
        var app = Application.getApp();
        var cx  = w / 2;

        // === TOP ROW SHAPES ===
        // Only draw shapes for elements that are visible
        var showHole    = app.showHoleNumber();
        var showPar     = app.showPar();
        var showStrokes = app.showStrokes() && !postHoleEntryMode;

        dc.setColor(0x7FA3DF, Graphics.COLOR_TRANSPARENT);
        if (showPar) {
            dc.fillRoundedRectangle(162, 22, 130, 55, 15);
        }
        if (showHole) {
            dc.fillCircle(104, 95, 45);
        }
        if (showStrokes) {
            dc.fillCircle(350, 95, 45);
        }

        // === TOP ROW LABELS ===
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (showHole) {
            dc.drawText(104, 65, Graphics.FONT_MEDIUM, state.holeNumber.toString(),
                Graphics.TEXT_JUSTIFY_CENTER);
        }
        if (showPar) {
            dc.drawText(227, 25, Graphics.FONT_SMALL, "Par: " + state.getPar(),
                Graphics.TEXT_JUSTIFY_CENTER);
        }
        if (showStrokes) {
            dc.drawText(350, 65, Graphics.FONT_MEDIUM, state.getCurrentHoleStrokes().toString(),
                Graphics.TEXT_JUSTIFY_CENTER);
        }

        // === COMPASS ARROW ===
        if (app.showArrow()) {
            _drawArrow(dc, cx, 140, 40, state.heading);
        }

        // === HOLE TIMER ===
        if (app.showHoleTimer()) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w/2, 190, Graphics.FONT_LARGE, state.getCurrentHoleTimeFormatted(),
                Graphics.TEXT_JUSTIFY_CENTER);
        }

        // ===  ROUND TIMER ===
        if (app.showRoundTimer()) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w/2, 385, Graphics.FONT_SMALL, state.getFormattedTime(),
                Graphics.TEXT_JUSTIFY_CENTER);
        }

        // === SPEED SCORE ===
        if (app.showSpeedScore()) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w/2, 250, Graphics.FONT_LARGE, "Score: " + state.getSpeedScore().format("%d"),
                Graphics.TEXT_JUSTIFY_CENTER);
        }

        // === BOTTOM ===
        if (app.showGolfScore()) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w/2, 340, Graphics.FONT_SMALL, "Strokes: " + state.strokeCount,
                Graphics.TEXT_JUSTIFY_CENTER);
        }

    }

    hidden function _drawCleanMode(dc, state, postHoleEntryMode, w, h) {
        var cx = w / 2;
        var cy = h / 2;

        // === TOP: hole circle (left) + par rect (center) + strokes circle (right, if not bulk) ===
        dc.setColor(0x7FA3DF, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(162, 22, 130, 55, 15);
        dc.fillCircle(104, 95, 45);
        if (!postHoleEntryMode) {
            dc.fillCircle(350, 95, 45);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(104, 65, Graphics.FONT_MEDIUM, state.holeNumber.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(227, 25, Graphics.FONT_SMALL,  "Par: " + state.getPar(),    Graphics.TEXT_JUSTIFY_CENTER);
        if (!postHoleEntryMode) {
            dc.drawText(350, 65, Graphics.FONT_MEDIUM, state.getCurrentHoleStrokes().toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }

        // === LARGE CENTERED ARROW ===
        _drawArrow(dc, cx, cy, 80, state.heading);
    }

    hidden function _drawArrow(dc, cx, cy, r, heading) {
        var tipX  = cx + (r * Math.sin(heading)).toNumber();
        var tipY  = cy - (r * Math.cos(heading)).toNumber();
        var tailX = cx - (r * 0.6 * Math.sin(heading)).toNumber();
        var tailY = cy + (r * 0.6 * Math.cos(heading)).toNumber();

        var wingAngle = heading - 2.4;
        var wingLX = cx + (r * 0.5 * Math.sin(wingAngle)).toNumber();
        var wingLY = cy - (r * 0.5 * Math.cos(wingAngle)).toNumber();

        wingAngle  = heading + 2.4;
        var wingRX = cx + (r * 0.5 * Math.sin(wingAngle)).toNumber();
        var wingRY = cy - (r * 0.5 * Math.cos(wingAngle)).toNumber();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[tipX, tipY], [wingLX, wingLY], [tailX, tailY], [wingRX, wingRY]]);
    }

    hidden function _drawGridMode(dc, state, bulkMode, w, h) {
        var app = Application.getApp();
        var cx  = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // === TOP BAR ===
        var topText = "";
        if (app.showHoleNumber() && app.showPar()) {
            topText = "Hole " + state.holeNumber + " · Par " + state.getPar();
        } else if (app.showHoleNumber()) {
            topText = "Hole " + state.holeNumber;
        } else if (app.showPar()) {
            topText = "Par " + state.getPar();
        }
        if (!topText.equals("")) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.15, Graphics.FONT_TINY, topText,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // === GRID LINES ===
        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(w * 0.12, h * 0.20, w * 0.88, h * 0.20);
        dc.drawLine(w * 0.06, h * 0.44, w * 0.94, h * 0.44);
        dc.drawLine(w * 0.06, h * 0.66, w * 0.94, h * 0.66);
        dc.drawLine(w * 0.12, h * 0.90, w * 0.88, h * 0.90);
        dc.drawLine(cx, h * 0.20, cx, h * 0.42);
        dc.drawLine(cx, h * 0.66, cx, h * 0.88);

        // === TOP LEFT: Hole Time ===
        if (app.showHoleTimer()) {
            dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0.275*w, h * 0.26, Graphics.FONT_XTINY, "Hole Time",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0.275*w, h * 0.36, Graphics.FONT_MEDIUM,
                state.getCurrentHoleTimeFormatted(),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // === TOP RIGHT: Hole Strokes ===
        if (app.showStrokes()) {
            dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0.725*w, h * 0.26, Graphics.FONT_XTINY, "Hole Strokes",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            if (!bulkMode) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(0.725*w, h * 0.36, Graphics.FONT_MEDIUM,
                    state.getCurrentHoleStrokes().toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
                dc.drawText(0.725*w, h * 0.36, Graphics.FONT_MEDIUM, "--",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
            // Auto-swing indicator: show for 3 elapsed seconds after detection
            if (state.autoSwingUntil > state.elapsedSeconds) {
                dc.setColor(0x5DCAA5, Graphics.COLOR_TRANSPARENT);
                dc.drawText(0.725*w, h * 0.42, Graphics.FONT_XTINY, "auto",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // === CENTER ROW: Arrow + Distance ===
        if (app.showArrow()) {
            _drawArrow(dc, 100, h * 0.54, 22, state.heading);
        
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx + 10, h * 0.54, Graphics.FONT_MEDIUM, "---",
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx + 65, h * 0.56, Graphics.FONT_XTINY, "to hole",
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // === BOTTOM LEFT: Round Time ===
        if (app.showRoundTimer()) {
            dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0.275*w, h * 0.70, Graphics.FONT_XTINY, "Round Time",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0.275*w, h * 0.79, Graphics.FONT_MEDIUM,
                state.getFormattedTime(),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // === BOTTOM RIGHT: vs Par ===
        if (app.showGolfScore()) {
            var parDiff      = state.getParDiff();
            var parDiffColor = Graphics.COLOR_WHITE;
            if (parDiff.equals("E"))                     { parDiffColor = 0x888888; }
            else if (parDiff.substring(0,1).equals("-")) { parDiffColor = 0x5DCAA5; }
            else                                         { parDiffColor = 0xF09595; }
            dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0.725*w, h * 0.70, Graphics.FONT_XTINY, "Round Strokes",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(parDiffColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0.725*w, h * 0.79, Graphics.FONT_MEDIUM, parDiff,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // === FOOTER: Speed Score ===
        if (app.showSpeedScore()) {
            dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.94, Graphics.FONT_XTINY,
                "Score: " + state.getSpeedScore().format("%d"),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }


}