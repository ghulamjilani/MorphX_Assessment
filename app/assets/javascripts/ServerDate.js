"use strict";

var ServerDate = function (serverNow) {
  // This is the first time we align with the server's clock by using the time
  // this script was generated (serverNow) and noticing the client time before
  // and after the script was loaded.  This gives us a good estimation of the
  // server's clock right away, which we later refine during synchronization.

  var // Remember when the script was loaded.
    scriptLoadTime = Date.now(),
    offset,
    target = null,
    systemChannel;

  // Everything is in the global function ServerDate.  Unlike Date, there is no
  // need for a constructor because there aren't instances.

  /// PUBLIC

  // Emulate Date's methods.

  function ServerDate() {
    // See http://stackoverflow.com/a/18543216/1330099.
    return this ? ServerDate : ServerDate.toString();
  }

  ServerDate.parse = Date.parse;
  ServerDate.UTC = Date.UTC;

  // Get calculated current server time
  ServerDate.now = function () {
    return Date.now() - offset;
  };

  // Get float seconds
  ServerDate.nowInSeconds = function () {
    return ServerDate.now() / 1000;
  };

  // Get int seconds
  ServerDate.nowInSecondsI = function () {
    return Math.round(ServerDate.nowInSeconds());
  };

  [
    // Populate ServerDate with the methods of Date's instances
    // that don't change state.

    "toString",
    "toDateString",
    "toTimeString",
    "toLocaleString",
    "toLocaleDateString",
    "toLocaleTimeString",
    "valueOf",
    "getTime",
    "getFullYear",
    "getUTCFullYear",
    "getMonth",
    "getUTCMonth",
    "getDate",
    "getUTCDate",
    "getDay",
    "getUTCDay",
    "getHours",
    "getUTCHours",
    "getMinutes",
    "getUTCMinutes",
    "getSeconds",
    "getUTCSeconds",
    "getMilliseconds",
    "getUTCMilliseconds",
    "getTimezoneOffset",
    "toUTCString",
    "toISOString",
    "toJSON",
  ].forEach(function (method) {
    ServerDate[method] = function () {
      return new Date(ServerDate.now())[method]();
    };
  });

  /// PRIVATE

  // We need to work with precision as well as offset values, so bundle them
  // together conveniently.
  function Offset(value) {
    this.value = value;
  }

  Offset.prototype.valueOf = function () {
    return this.value;
  };

  Offset.prototype.toString = function () {
    return this.value + " ms";
  };

  // The target is the offset we'll get to over time after amortization.
  function setTarget(newTarget) {
    var message = "Set target to " + String(newTarget),
      delta;

    if (target)
      message +=
        " (" +
        (newTarget > target ? "+" : "-") +
        " " +
        Math.abs(newTarget - target) +
        " ms)";

    target = newTarget;
  }

  offset = scriptLoadTime - serverNow;

  // Not yet supported by all browsers (including Safari).  Calculate the
  // precision based on when the HTML page has finished loading and begins to load
  // this script from the server.

  // firefox widowed mode doen't work
  //if (typeof performance != "undefined") {
  //  precision = (scriptLoadTime - performance.timing.domLoading) / 2;
  //  offset += precision;
  //}

  // Set the target to the initial offset.
  setTarget(new Offset(offset));

  // data = { time_now: "2022-03-21T15:26:38.649+00:00", time_now_i: "1647876398", time_now_ms: "1647876398649" }
  function updateOffset(data) {
    offset = Date.now() - Date.parse(data.time_now);
  }

  systemChannel = initSystemChannel();
  systemChannel.bind(systemChannelEvents.serverTime, updateOffset);
  // Synchronize whenever the page is shown again after losing focus.
  // window.addEventListener('pageshow', synchronize);

  // Start our first synchronization.
  // synchronize();

  // Return the newly defined module.
  return ServerDate;
};

window.serverDate = ServerDate(serverTime);
