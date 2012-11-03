(function() {
  var define,
    __slice = [].slice;

  if (typeof define !== "function") {
    define = require("amdefine")(module);
  }

  define(function(require) {
    var Observable;
    return Observable = {
      set: function() {
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
      },
      get: function(key) {
        return this[key];
      },
      invalidate: function(key) {
        var observer, observers, _i, _len, _results;
        observers = this._getObserversByKey()[key];
        if (observers != null) {
          _results = [];
          for (_i = 0, _len = observers.length; _i < _len; _i++) {
            observer = observers[_i];
            _results.push(observer());
          }
          return _results;
        }
      },
      on: function(key, observer) {
        var _base, _ref;
        if ((_ref = (_base = this._getObserversByKey())[key]) == null) {
          _base[key] = [];
        }
        return this._getObserversByKey()[key].push(observer);
      },
      off: function(key, observer) {
        var i, os, _ref;
        os = this._getObserversByKey()[key];
        if (os != null) {
          i = os.indexOf(observer);
          if (i !== -1) {
            return ([].splice.apply(os, [i, i - i + 1].concat(_ref = [])), _ref);
          }
        }
      },
      _setOne: function(key, value) {
        this[key] = value;
        return this.invalidate(key);
      },
      _getObserversByKey: function() {
        var _ref;
        return (_ref = this._observersByKey) != null ? _ref : this._observersByKey = {};
      }
    };
  });

}).call(this);
