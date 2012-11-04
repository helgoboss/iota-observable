if (typeof define !== 'function') { var define = require('amdefine')(module) };

var __slice = [].slice;

define(function(require) {
  var Observable;
  return Observable = (function() {

    Observable.makeObservable = function(obj) {
      var key, value, _ref;
      _ref = this.prototype;
      for (key in _ref) {
        value = _ref[key];
        obj[key] = value;
      }
      return obj._init();
    };

    function Observable(obj) {
      var key, value;
      this._init();
      if (obj != null) {
        for (key in obj) {
          value = obj[key];
          this[key] = value;
        }
      }
    }

    Observable.prototype.set = function() {
      var args, keypath, properties, value, _results;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (args.length === 1) {
        properties = args[0];
        _results = [];
        for (keypath in properties) {
          value = properties[keypath];
          _results.push(this._setOne(keypath, value));
        }
        return _results;
      } else {
        return this._setOne(args[0], args[1]);
      }
    };

    Observable.prototype.get = function(keypath) {
      var segments;
      segments = keypath.split(".");
      return this._followAndGetKeypathSegments(this, segments);
    };

    Observable.prototype.invalidate = function(keypath) {
      var observer, observers, _i, _len, _results;
      observers = this._observersByKeypath[keypath];
      if (observers != null) {
        _results = [];
        for (_i = 0, _len = observers.length; _i < _len; _i++) {
          observer = observers[_i];
          _results.push(observer());
        }
        return _results;
      }
    };

    Observable.prototype.on = function(keypath, observer) {
      var _base, _ref;
      if ((_ref = (_base = this._observersByKeypath)[keypath]) == null) {
        _base[keypath] = [];
      }
      return this._observersByKeypath[keypath].push(observer);
    };

    Observable.prototype.off = function(keypath, observer) {
      var i, os, _ref;
      os = this._observersByKeypath[keypath];
      if (os != null) {
        i = os.indexOf(observer);
        if (i !== -1) {
          return ([].splice.apply(os, [i, i - i + 1].concat(_ref = [])), _ref);
        }
      }
    };

    Observable.prototype._init = function() {
      return this._observersByKeypath = {};
    };

    Observable.prototype._setOne = function(keypath, value) {
      var segments, successful;
      segments = keypath.split(".");
      successful = this._followAndSetKeypathSegments(this, segments, value);
      if (successful) {
        this.invalidate(keypath);
      }
      return successful;
    };

    Observable.prototype._followAndGetKeypathSegments = function(parent, segments) {
      var firstSegment, resolvedObject;
      if (segments.length === 1) {
        if (this._getObjectType(parent) === "observableLike") {
          return parent.get(segments[0]);
        } else {
          return parent[segments[0]];
        }
      } else {
        if (this._getObjectType(parent) === "observableLike") {
          return parent.get(segments.join("."));
        } else {
          firstSegment = segments.shift();
          if (firstSegment in parent) {
            resolvedObject = parent[firstSegment];
            return this._followAndGetKeypathSegments(resolvedObject, segments);
          } else {
            return void 0;
          }
        }
      }
    };

    Observable.prototype._followAndSetKeypathSegments = function(parent, segments, value) {
      var firstSegment, resolvedObject;
      if (segments.length === 1) {
        switch (this._getObjectType(parent)) {
          case "observableLike":
            parent.set(segments[0], value);
            return true;
          case "mapLike":
          case "self":
            parent[segments[0]] = value;
            return true;
          default:
            return false;
        }
      } else {
        if (this._getObjectType(parent) === "observableLike") {
          return parent.set(segments.join("."), value);
        } else {
          firstSegment = segments.shift();
          resolvedObject = firstSegment in parent ? parent[firstSegment] : parent[firstSegment] = {};
          return this._followAndSetKeypathSegments(resolvedObject, segments, value);
        }
      }
    };

    Observable.prototype._getObjectType = function(obj) {
      if (obj != null) {
        if (obj === this) {
          return "self";
        } else if (typeof obj.set === "function") {
          return "observableLike";
        } else if (Object.prototype.toString.call(obj) === "[object Array]") {
          return "array";
        } else if (obj instanceof Object) {
          return "mapLike";
        } else {
          return "other";
        }
      } else {
        return "nullLike";
      }
    };

    return Observable;

  })();
});
