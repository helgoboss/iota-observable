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
      var args, key, properties, value, _results;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (args.length === 1) {
        properties = args[0];
        _results = [];
        for (key in properties) {
          value = properties[key];
          _results.push(this._setOne(key, value));
        }
        return _results;
      } else {
        return this._setOne(args[0], args[1]);
      }
    };

    Observable.prototype.get = function(key) {
      var result;
      result = this._processKeypath(key);
      if (result.resolvedParent != null) {
        return result.resolvedParent[result.lastSegment];
      } else {
        return void 0;
      }
    };

    Observable.prototype.invalidate = function(key) {
      var observer, observers, _i, _len, _results;
      observers = this._observersByKey[key];
      if (observers != null) {
        _results = [];
        for (_i = 0, _len = observers.length; _i < _len; _i++) {
          observer = observers[_i];
          _results.push(observer());
        }
        return _results;
      }
    };

    Observable.prototype.on = function(key, observer) {
      var _base, _ref;
      if ((_ref = (_base = this._observersByKey)[key]) == null) {
        _base[key] = [];
      }
      return this._observersByKey[key].push(observer);
    };

    Observable.prototype.off = function(key, observer) {
      var i, os, _ref;
      os = this._observersByKey[key];
      if (os != null) {
        i = os.indexOf(observer);
        if (i !== -1) {
          return ([].splice.apply(os, [i, i - i + 1].concat(_ref = [])), _ref);
        }
      }
    };

    Observable.prototype._init = function() {
      return this._observersByKey = {};
    };

    Observable.prototype._setOne = function(key, value) {
      var result;
      result = this._processKeypath(key);
      if (result.resolvedParent != null) {
        result.resolvedParent[result.lastSegment] = value;
        return this.invalidate(key);
      }
    };

    Observable.prototype._processKeypath = function(keypath) {
      var segments;
      segments = keypath.split(".");
      return this._processKeypathSegments(this, segments);
    };

    Observable.prototype._processKeypathSegments = function(parent, segments) {
      var firstSegment, resolvedObject;
      if (segments.length === 1) {
        return {
          resolvedParent: parent,
          lastSegment: segments[0]
        };
      } else {
        firstSegment = segments.shift();
        resolvedObject = parent[firstSegment];
        return this._processKeypathSegments(resolvedObject, segments);
      }
    };

    return Observable;

  })();
});
