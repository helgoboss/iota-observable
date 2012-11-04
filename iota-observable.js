if (typeof define !== 'function') { var define = require('amdefine')(module) };

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

define(function(require) {
  var Observable;
  return Observable = (function() {

    Observable.SetOperationFailed = (function(_super) {

      __extends(_Class, _super);

      function _Class(obj, key, value) {
        this.message = "Setting [" + key + "] to [" + value + "] on [" + obj + "] failed";
      }

      return _Class;

    })(Error);

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
      var dependentKeypath, segments, _base, _ref;
      segments = keypath.split(".");
      if (this._computedPropertyStack.length > 0) {
        dependentKeypath = this._computedPropertyStack[this._computedPropertyStack.length - 1];
        if ((_ref = (_base = this._dependentKeypathsByKeypath)[keypath]) == null) {
          _base[keypath] = {};
        }
        this._dependentKeypathsByKeypath[keypath][dependentKeypath] = true;
      }
      return this._followAndGetKeypathSegments(this, segments, keypath);
    };

    Observable.prototype.invalidate = function(keypath, oldValue, newValue) {
      var dependentKeypath, dependentKeypaths, observer, observers, _i, _len, _results;
      observers = this._observersByKeypath[keypath];
      if (observers != null) {
        for (_i = 0, _len = observers.length; _i < _len; _i++) {
          observer = observers[_i];
          observer(oldValue, newValue);
        }
      }
      dependentKeypaths = this._dependentKeypathsByKeypath[keypath];
      if (dependentKeypaths != null) {
        _results = [];
        for (dependentKeypath in dependentKeypaths) {
          _results.push(this.invalidate(dependentKeypath, null, null));
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
      var i, observers, _ref;
      observers = this._observersByKeypath[keypath];
      if (observers != null) {
        i = observers.indexOf(observer);
        if (i !== -1) {
          return ([].splice.apply(observers, [i, i - i + 1].concat(_ref = [])), _ref);
        }
      }
    };

    Observable.prototype._init = function() {
      this._observersByKeypath = {};
      this._dependentKeypathsByKeypath = {};
      return this._computedPropertyStack = [];
    };

    Observable.prototype._setOne = function(keypath, value) {
      var oldValue, segments;
      segments = keypath.split(".");
      oldValue = this._followAndSetKeypathSegments(this, segments, value);
      this.invalidate(keypath, oldValue, value);
      return oldValue;
    };

    Observable.prototype._followAndGetKeypathSegments = function(parent, segments, keypath) {
      var firstSegment, resolvedObject;
      if (segments.length === 1) {
        if (this._getObjectType(parent) === "observableLike") {
          return parent.get(segments[0]);
        } else {
          return this._invokeIfNecessary(parent[segments[0]], keypath);
        }
      } else {
        if (this._getObjectType(parent) === "observableLike") {
          return parent.get(segments.join("."));
        } else {
          firstSegment = segments.shift();
          if (firstSegment in parent) {
            resolvedObject = this._invokeIfNecessary(parent[firstSegment], keypath);
            return this._followAndGetKeypathSegments(resolvedObject, segments, keypath);
          } else {
            return void 0;
          }
        }
      }
    };

    Observable.prototype._followAndSetKeypathSegments = function(parent, segments, value) {
      var firstSegment, oldValue, resolvedObject;
      if (segments.length === 1) {
        switch (this._getObjectType(parent)) {
          case "observableLike":
            oldValue = parent.get(segments[0]);
            parent.set(segments[0], value);
            return oldValue;
          case "mapLike":
          case "self":
            oldValue = parent[segments[0]];
            parent[segments[0]] = value;
            return oldValue;
          default:
            throw new Observable.SetOperationFailed(parent, segments[0], value);
        }
      } else {
        if (this._getObjectType(parent) === "observableLike") {
          return parent.set(segments.join("."), value);
        } else {
          firstSegment = segments.shift();
          resolvedObject = firstSegment in parent ? this._invokeIfNecessary(parent[firstSegment], null) : parent[firstSegment] = {};
          return this._followAndSetKeypathSegments(resolvedObject, segments, value);
        }
      }
    };

    Observable.prototype._invokeIfNecessary = function(obj, keypath) {
      if (typeof obj === "function") {
        this._computedPropertyStack.push(keypath);
        try {
          return obj.apply(this);
        } finally {
          this._computedPropertyStack.pop();
        }
      } else {
        return obj;
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
