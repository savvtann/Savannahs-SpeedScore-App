using Toybox.WatchUi;

class SearchResultsView extends WatchUi.Menu2 {
    hidden var _results;

    function initialize(results) {
        Menu2.initialize({:title => "Results"});
        _results = results;

        if (results == null || results.size() == 0) {
            addItem(new WatchUi.MenuItem("No courses found", null, :none, {}));
        } else {
            for (var i = 0; i < results.size(); i++) {
                addItem(new WatchUi.MenuItem(results[i]["name"], null, i, {}));
            }
        }
    }

    function getResults() { return _results; }
}
