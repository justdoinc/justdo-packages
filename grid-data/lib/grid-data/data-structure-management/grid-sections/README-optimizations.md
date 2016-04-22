grid-sections optimizations
===========================

As GridData's _each() is in the core of our system and essential for its
performance, effort was given to optimize it by relying on existing data
in @grid_tree and @_grid_tree_filter_state to avoid re-calculations when
necessary.

The following can be used to test the optimizations improvements and
correctness:

Setup
-----

Duplicate _each's code in grid-section.coffee and name the duplicate: `_each_non_optimized`

Replace the code under the condition:

    if absolute_path != "/" or root_path_refers_to_main_section
        ...

with:

    if absolute_path != "/" or root_path_refers_to_main_section
        # Forward to the path's each
        section = @getPathSection(absolute_path)

        relative_path = section.section_manager.relPath absolute_path

        return section.section_manager._each(relative_path, options, iteratee)

Replace line:

    _each_res = @_each section.path, options, iteratee, true

with

    _each_res = @_each_non_optimized section.path, options, iteratee, true


Testing
-------

In the browser:

* Open a massive project with many sections
* Expand some paths
* Activate a filter

Insert the following in the console:

    function getCurrentGridControl() {
      return APP.modules.project_page.grid_control.get();
    }

    function getCurrentGridData() {
      return getCurrentGridControl()._grid_data
    }

    function traverseTree(path, options, iteratee, optimize) {
      var grid_data = getCurrentGridData();

      if (typeof iteratee === "undefined") {
        iteratee = function () {};
      }

      if (typeof options === "undefined") {
        options = {};
      }

      if (typeof path === "undefined") {
        path = "/";
      }

      if (optimize) {
        return grid_data._each(path, options, iteratee);
      } else {
      return grid_data._each_non_optimized(path, options, iteratee);
      }

    }

    function timeTreeTraverse(path, options, iteratee, optimize) {
      return JustdoHelpers.timeProfile(function () {traverseTree(path, options, iteratee, optimize)});
    }

    function getTreeTraverse(path, options, optimize) {
      var result = [];

      traverseTree(path, options, function (a,b,c,d,e) {result.push([b,d,e])}, optimize);

      return result;
    }

    function timeSimpleTreeTraverse(options, optimize) {
      var x = 0;

      time = timeTreeTraverse("/", options, function () {x++;}, optimize);

      return time;
    }

    function averageOutput(times, op) {
      var aggr = 0;

      for (i = j = 0, ref = times; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
        aggr += op();
      }

      return aggr / times;
    }

    function simpleTraverseAverageOutput(times, options, optimize) {
      return averageOutput(times, function () {return timeSimpleTreeTraverse(options, optimize);})
    }

    function compareOptimizeToNonOptimize(times_to_run, options) {
      var optimized = simpleTraverseAverageOutput(times_to_run, options, true);
      var non_optimized = simpleTraverseAverageOutput(times_to_run, options, false);
      return optimized / non_optimized;
    }

    function compareOptimizeToNonOptimizeOutput(path, options) {
      var optimized = JSON.stringify(getTreeTraverse(path, options, true));
      var non_optimized = JSON.stringify(getTreeTraverse(path, options, false))
      return optimized == non_optimized;
    }

    // Efficiency test
    times_to_run = 100;
    console.log(compareOptimizeToNonOptimize(times_to_run, {expand_only: false, filtered_tree: false}));
    console.log(compareOptimizeToNonOptimize(times_to_run, {expand_only: true, filtered_tree: false}));
    times_to_run = 30;
    console.log(compareOptimizeToNonOptimize(times_to_run, {expand_only: false, filtered_tree: true}));
    console.log(compareOptimizeToNonOptimize(times_to_run, {expand_only: true, filtered_tree: true}));

    // Correcteness test

    var i, len, path, paths_to_test;
    paths_to_test = ["/", "/main2/", "/main14/ZdGkCsetGBwZx5vYR/"];
    for (i = 0, len = paths_to_test.length; i < len; i++) {
      path = paths_to_test[i];

      console.log(compareOptimizeToNonOptimizeOutput("/", {expand_only: false, filtered_tree: false}));
      console.log(compareOptimizeToNonOptimizeOutput("/", {expand_only: true, filtered_tree: false}));
      console.log(compareOptimizeToNonOptimizeOutput("/", {expand_only: false, filtered_tree: true}));
      console.log(compareOptimizeToNonOptimizeOutput("/", {expand_only: true, filtered_tree: true}));
    }

Results
-------

As of April 7th 2016, on Chrome under MacBook Air:

* All correctness check passed

* Optimizations run improvement:
  * {expand_only: false, filtered_tree: false} : 0.9117217040584826
  * {expand_only: true, filtered_tree: false} : 0.028978840846366143

  * When filter leave empty tree:
    * {expand_only: false, filtered_tree: true} : 0.12467548914075859
    * {expand_only: true, filtered_tree: true} : 0.3925443521221648
  * When few < 10 items pass the filter:
    * {expand_only: false, filtered_tree: true} : 0.0623764401118004
    * {expand_only: true, filtered_tree: true} : 0.21434460016488047
  * When most items pass the filter:
    * {expand_only: false, filtered_tree: true} : 0.873915199603273
    * {expand_only: true, filtered_tree: true} : 0.4388966480446927