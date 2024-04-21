Grid Controls Multiplexer
=========================

Events
------

* **tab-ready(tab_obj):** [REACTIVITY_READY] Fires immediately after (sync,
not next flush) the state property of a tab changes to "ready".

* **tab-unload(tab_obj):** [REACTIVITY_READY] Fires right before
we begin the tab unload procedures (i.e. tab_obj) is still in its
pre-unload state.

Notes:

1. [REACTIVITY_READY] means tab_obj is passed by reference, following tab-
ready, event the Tracker.Dependency responsible for tabs data reactivity is
always invalidating - hence you can trust changes you make to tab_obj.
