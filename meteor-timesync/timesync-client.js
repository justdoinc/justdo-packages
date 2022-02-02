//IE8 doesn't have Date.now()
Date.now = Date.now || function() { return +new Date; };

TimeSync = {
  loggingEnabled: true
};

function log(/* arguments */) {
  if (TimeSync.loggingEnabled) {
    Meteor._debug.apply(this, arguments);
  }
}

// Resync if unexpected change by more than a few seconds. This needs to be
// somewhat lenient, or a CPU-intensive operation can trigger a re-sync even
// when the offset is still accurate. In any case, we're not going to be able to
// catch very small system-initiated NTP adjustments with this, anyway.
var tickCheckTolerance = 5000;

var defaultInterval = 1000;

var resync_interval_ms = 10 * 60 * 1000;

// Internal values, exported for testing
SyncInternals = {
  offset: undefined,
  roundTripTime: undefined,
  offsetDep: new Deps.Dependency(),
  ready: new $.Deferred(),
  sync_failed: new ReactiveVar(false),

  timeCheck: function (lastTime, currentTime, interval, tolerance) {
    if (Math.abs(currentTime - lastTime - interval) < tolerance) {
      // Everything is A-OK
      return true;
    }
    // We're no longer in sync.
    return false;
  }
};

var maxAttempts = 5;
var attempts = 0;

/*
  This is an approximation of
  http://en.wikipedia.org/wiki/Network_Time_Protocol

  If this turns out to be more accurate under the connect handlers,
  we should try taking multiple measurements.
 */

// Only use Meteor.absoluteUrl for Cordova; see
// https://github.com/meteor/meteor/issues/4696
// https://github.com/mizzao/meteor-timesync/issues/30
var syncUrl = "/_timesync";
if (Meteor.isCordova) {
  syncUrl = Meteor.absoluteUrl("_timesync");
}

var updateOffset = function() {
  attempts = 0;

  var t0 = Date.now();

  HTTP.get(syncUrl, function(err, response) {
    var t3 = Date.now(); // Grab this now
    if (err || response.content.length > 15) { // 2 bytes added for redundancy
      //  We'll still use our last computed offset if is defined
      log("Error syncing to server time: ", err);
      SyncInternals.sync_failed.set(true);
      if (++attempts <= maxAttempts)
        Meteor.setTimeout(TimeSync.resync, 1000);
      else
        log("Max number of time sync attempts reached. Giving up.");
      return;
    }

    SyncInternals.sync_failed.set(false);
    SyncInternals.ready.resolve();

    attempts = 0; // It worked

    var ts = parseInt(response.content);
    SyncInternals.offset = Math.round(((ts - t0) + (ts - t3)) / 2);
    SyncInternals.roundTripTime = t3 - t0; // - (ts - ts) which is 0
    SyncInternals.offsetDep.changed();
  });
};

TimeSync.getServerTime = function(date_object_in_client_time) {
  // COFFEESCRIPT Code:
  //
  // TimeSync.getServerTime = (date_object_in_client_time) ->
  //   SyncInternals.offsetDep.depend()
  //
  //   # If we don't know the offset, we can't provide the server time.
  //   if not TimeSync.isSynced()?
  //     return undefined
  //
  //   if not (client_time = date_object_in_client_time?.getTime())?
  //     client_time = Date.now()
  //
  //   return client_time + SyncInternals.offset

  var client_time;
  SyncInternals.offsetDep.depend();
  // If we don't know the offset, we can't provide the server time.
  if (TimeSync.isSynced() == null) {
    return void 0;
  }
  if ((client_time = date_object_in_client_time != null ? date_object_in_client_time.getTime() : void 0) == null) {
    client_time = Date.now();
  }
  return client_time + SyncInternals.offset;
};

TimeSync.getServerOffset = function() {
  return SyncInternals.offset;
};

TimeSync.roundTripTime = function() {
  return SyncInternals.roundTripTime;
};

TimeSync.isSynced = function() {
  return SyncInternals.offset !== undefined;
};

TimeSync.ready = function(cb) {
  return SyncInternals.ready.done(cb);
};

var resyncIntervalId = null;

TimeSync.resync = function() {
  if (resyncIntervalId !== null) Meteor.clearInterval(resyncIntervalId);
  updateOffset();
  resyncIntervalId = Meteor.setInterval(updateOffset, resync_interval_ms);
};

// Run this as soon as we load, even before Meteor.startup()
// Run again whenever we reconnect after losing connection
var wasConnected = false;

Deps.autorun(function() {
  var connected = Meteor.status().connected;
  if ( connected && !wasConnected ) TimeSync.resync();
  wasConnected = connected;
});

var lastClientTime = Date.now();

// Set up special interval for the default tick, which also watches for re-sync
Meteor.setInterval(function() {
  var currentClientTime = Date.now();

  if ( SyncInternals.timeCheck(
    lastClientTime, currentClientTime, defaultInterval, tickCheckTolerance) ) {
    // No problem here
  }
  else {
    // resync on major client clock changes
    // based on http://stackoverflow.com/a/3367542/1656818
    log("Clock discrepancy detected. Attempting re-sync.");

    TimeSync.resync();
  }

  lastClientTime = currentClientTime;
}, defaultInterval);

Template.timesync_status.helpers({
  sync_failed: function() {
    return SyncInternals.sync_failed.get();
  },
  connected: function () {
    return Meteor.status().connected;
  }
});

Template.timesync_status.events({
  "click #timesync-reconnect": function(e) {
    TimeSync.resync();
  }
});