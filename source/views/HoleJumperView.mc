using Toybox.WatchUi;

class HoleJumperView extends WatchUi.Menu2 {
    function initialize(totalHoles, holeData) {
        Menu2.initialize({:title => "Next Hole"});
        for (var i = 1; i <= totalHoles; i++) {
            if (!_isPlayed(i, holeData)) {
                addItem(new WatchUi.MenuItem("Hole " + i, null, i, {}));
            }
        }
    }

    hidden function _isPlayed(holeNum, holeData) {
        for (var i = 0; i < holeData.size(); i++) {
            if (holeData[i]["number"] == holeNum) {
                return true;
            }
        }
        return false;
    }
}
