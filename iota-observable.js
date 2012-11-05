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
      var args, keypath, oldValue, properties, transactionStarted, value;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      transactionStarted = this.startTransaction();
      oldValue = (function() {
        var _results;
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
      }).call(this);
      if (transactionStarted) {
        this.commit();
      }
      return oldValue;
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
      var dependentKeypath, dependentKeypaths, transactionStarted;
      transactionStarted = this.startTransaction();
      if (keypath in this._invalidationByKeypath) {
        this._invalidationByKeypath[keypath].newValue = newValue;
      } else {
        this._invalidationByKeypath[keypath] = {
          oldValue: oldValue,
          newValue: newValue
        };
      }
      dependentKeypaths = this._dependentKeypathsByKeypath[keypath];
      if (dependentKeypaths != null) {
        for (dependentKeypath in dependentKeypaths) {
          this.invalidate(dependentKeypath, null, null);
        }
      }
      if (transactionStarted) {
        return this.commit();
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

    Observable.prototype.startTransaction = function() {
      if (this._inTransaction) {
        return false;
      } else {
        this._inTransaction = true;
        return true;
      }
    };

    Observable.prototype.commit = function() {
      var invalidation, keypath, observer, observers, _i, _len, _ref;
      if (this._inTransaction) {
        this._inTransaction = false;
        _ref = this._invalidationByKeypath;
        for (keypath in _ref) {
          invalidation = _ref[keypath];
          observers = this._observersByKeypath[keypath];
          if (observers != null) {
            for (_i = 0, _len = observers.length; _i < _len; _i++) {
              observer = observers[_i];
              observer(keypath, invalidation.oldValue, invalidation.newValue);
            }
          }
          delete this._invalidationByKeypath[keypath];
        }
        return true;
      } else {
        return false;
      }
    };

    Observable.prototype._init = function() {
      this._observersByKeypath = {};
      this._dependentKeypathsByKeypath = {};
      this._computedPropertyStack = [];
      this._inTransaction = false;
      return this._invalidationByKeypath = {};
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
