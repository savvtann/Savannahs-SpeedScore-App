using Toybox.WatchUi;
using Toybox.Application;

class HomeDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _screenManager;

    function initialize(screenManager) {
        Menu2InputDelegate.initialize();
        _screenManager = screenManager;
    }

    function onSelect(item) {
        var id  = item.getId();
        var app = Application.getApp();

        if (id == :startRound) {
            Application.getApp().goToCourseSelection();
        } else if (id == :roundHistory) {
            app._roundFlowDepth = 1;
            WatchUi.pushView(
                new RoundHistoryLoadingView(),
                new RoundHistoryLoadingDelegate(),
                WatchUi.SLIDE_LEFT
            );
            app._apiClient.fetchMyRounds(method(:onRoundsLoaded));
        } else if (id == :myCourses) {
            var favs = app.getSortedFavoriteCourses();
            app._roundFlowDepth = 1;
            WatchUi.pushView(
                new MyCoursesView(favs),
                new MyCoursesDelegate(_screenManager, favs),
                WatchUi.SLIDE_LEFT
            );
        } else if (id == :settings) {
            _screenManager.goToSettings();
        }
    }

    function onRoundsLoaded(responseCode, data) {
        var rounds = [];
        if (responseCode == 200 && data instanceof Array) {
            rounds = data;
            // Sort by date descending (newest first)
            for (var i = 0; i < rounds.size() - 1; i++) {
                for (var j = 0; j < rounds.size() - 1 - i; j++) {
                    var a = _dateToInt(rounds[j]["date"] != null ? rounds[j]["date"] : rounds[j]["createdAt"]);
                    var b = _dateToInt(rounds[j + 1]["date"] != null ? rounds[j + 1]["date"] : rounds[j + 1]["createdAt"]);
                    if (a < b) {
                        var tmp    = rounds[j];
                        rounds[j]  = rounds[j + 1];
                        rounds[j + 1] = tmp;
                    }
                }
            }
        } else {
            System.println("fetchMyRounds failed: " + responseCode);
        }
        WatchUi.switchToView(
            new RoundHistoryView(rounds),
            new RoundHistoryDelegate(_screenManager, rounds),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    hidden function _dateToInt(dateStr) {
        if (dateStr == null || dateStr.length() < 10) { return 0; }
        var y = 0; var m = 0; var d = 0;
        if (dateStr.substring(2, 3).equals("-")) {
            // MM-DD-YYYY (date field)
            m = dateStr.substring(0, 2).toNumber();
            d = dateStr.substring(3, 5).toNumber();
            y = dateStr.substring(6, 10).toNumber();
        } else {
            // YYYY-MM-DD... (createdAt fallback)
            y = dateStr.substring(0, 4).toNumber();
            m = dateStr.substring(5, 7).toNumber();
            d = dateStr.substring(8, 10).toNumber();
        }
        if (y == null) { y = 0; }
        if (m == null) { m = 0; }
        if (d == null) { d = 0; }
        return y * 10000 + m * 100 + d;
    }

}