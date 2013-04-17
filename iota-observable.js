if (typeof define !== 'function') { var define = require('amdefine')(module) };

var Observable,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

Observable = (function() {
  /*
    An object which notifies observers whenever a property is changed using `set`.
  */

  Observable.SetOperationFailed = (function(_super) {

    __extends(_Class, _super);

    /*
        Error thrown if a property value could not be set.
    */


    function _Class(obj, key, value) {
      this.message = "Setting [" + key + "] to [" + value + "] on [" + obj + "] failed";
    }

    return _Class;

  })(Error);

  Observable.makeObservable = function(obj) {
    /*
        Makes the given object `obj` observable by copying all `Observable` methods to it and initializing the `Observable`'s state.
    */

    var key, value, _ref;
    _ref = this.prototype;
    for (key in _ref) {
      value = _ref[key];
      obj[key] = value;
    }
    return obj._init();
  };

  function Observable(obj) {
    /*
        Initializes the Observable. If `obj` is given, all its properties are copied into the new `Observable`.
    */

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
    var args, batchStarted, keypath, oldValue, properties, value;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    /*
        Sets the values of one or several properties of this object or nested objects and informs observers.
        
        If a single argument is passed, it is assumed to be an object containing keypath-value pairs. If two arguments 
        are passed, the first one is interpreted as the keypath and the second one as the value.
        
        The property is identified by its keypath using the dot notation. The implementation follows the keypath 
        and sets the referenced property to the given value. If it meets a dead end on the path (an object which 
        doesn't contain the property which comes next on the keypath), it just creates an empty object and continues 
        with the rest of the keypath. If it cannot set the value because it stumbles upon a defined property whose type is 
        not an object, it throws an `Observable.SetOperationFailed` error.
        
        Returns the old value or `undefined` if there was none. If multiple properties are set, returns and array of old values.
    */

    batchStarted = this.beginBatch();
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
    if (batchStarted) {
      this.endBatch();
    }
    return oldValue;
  };

  Observable.prototype.get = function(keypath) {
    /* 
    Returns the property identified by the given keypath.
    
    Also handles computed properties by evaluating them. If other properties are queried using `get` during the evaluation of the
    computed property, their dependencies are tracked.
    */

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
    /*
        Manually informs the observers about a change in the property with the given keypath. This is for example necessary
        when dealing with changes in array properties.
        
        Delays the notification if a batch is active until `endBatch` is called.
    */

    var batchStarted, dependentKeypath, dependentKeypaths;
    batchStarted = this.beginBatch();
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
    if (batchStarted) {
      return this.endBatch();
    }
  };

  Observable.prototype.on = function(keypath, observer) {
    /* 
    Registers the given observer for the given object property keypath.
    */

    var _base, _ref;
    if ((_ref = (_base = this._observersByKeypath)[keypath]) == null) {
      _base[keypath] = [];
    }
    return this._observersByKeypath[keypath].push(observer);
  };

  Observable.prototype.off = function(keypath, observer) {
    /* 
    Unregisters the given observer for the given object property keypath.
    
    If the observer was not registered before, this method has no effect.
    */

    var i, observers, _ref;
    observers = this._observersByKeypath[keypath];
    if (observers != null) {
      i = observers.indexOf(observer);
      if (i !== -1) {
        return ([].splice.apply(observers, [i, i - i + 1].concat(_ref = [])), _ref);
      }
    }
  };

  Observable.prototype.beginBatch = function() {
    /*
        Starts a batch. 
        
        Within a batch, observers are not notified of changes. They will be notified as soon as `endBatch` is called.
        
        If a batch was already active, the method has no effect and returns false.
    */
    if (this._inBatch) {
      return false;
    } else {
      this._inBatch = true;
      return true;
    }
  };

  Observable.prototype.endBatch = function() {
    /*
        Ends the batch and carries out the delayed observer notifications.
        
        If no batch was active, the method has no effect and returns false.
    */

    var invalidation, keypath, observer, observers, _i, _len, _ref;
    if (this._inBatch) {
      this._inBatch = false;
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
    this._inBatch = false;
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

define(function(require) {
  return Observable;
});
