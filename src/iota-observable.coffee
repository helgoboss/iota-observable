# See "amdefine" on github
`if (typeof define !== 'function') { var define = require('amdefine')(module) }`

define (require) ->
  class Observable
    @SetOperationFailed: class extends Error
      constructor: (obj, key, value) ->
        @message = "Setting [#{key}] to [#{value}] on [#{obj}] failed"
    
    # Static method used to mixin the Observable methods to the given object and initialize it.
    @makeObservable: (obj) ->
      # Copy Observable's prototype properties to the object
      for key, value of @::
        obj[key] = value
        
      # Initialize object
      obj._init()
        
    # Initializes the Observable. If an object is given, all its properties are copied into the Observable.
    constructor: (obj) ->
      # Initialize
      @_init()
      
      # Copy properties of obj
      if obj?
        for key, value of obj
          @[key] = value
  
    # Sets one or several properties of this object and informs observers.
    # Can take a single map parameter or two parameters: keypath, value.
    # Follows the keypath and sets the referenced property to the given value.
    # If it meets a dead end on the path (an object which doesn't define the
    # property next on the keypath), it just creates an empty object and continues following.
    # Returns the old value or undefined if there was none. If it cannot set the value because
    # it stumbles upon a defined property whose type is not map-like, it throws an error.
    # If multiple properties are set, returns and array of old values.
    set: (args...) ->
      if args.length == 1
        # A map containing new keypath-value pairs has been given
        properties = args[0]
        for keypath, value of properties
          @_setOne(keypath, value)
      else
        # Two arguments (a keypath and a value) have been given
        @_setOne(args[0], args[1])
        
        
    # Returns the property with the given keypath.
    get: (keypath) ->
      # Split keypath into segments
      segments = keypath.split(".")
      
      # Record dependencies
      if @_computedPropertyStack.length > 0
        # We are just evaluating a computed property c. And we are in the get method of property d.
        # That means, the computation of property c uses property d. We can also say, the computed
        # property c depends on d. So later, whenever we set d, we also need to inform the observers of d
        # because it most likely changed as well.
        
        # Build up a relation "when property 'keypath' (computed or not) changed, also inform computed property 'dependentKeypath'"
        # We could do this also using the already available observer mechanism: @on keypath, => @invalidate(dependentKeypath)
        # But then we don't have the option to separate the (kind of implicit) computed property observer calls from the rest.
        dependentKeypath = @_computedPropertyStack[@_computedPropertyStack.length - 1]
        @_dependentKeypathsByKeypath[keypath] ?= {}
        @_dependentKeypathsByKeypath[keypath][dependentKeypath] = true
      
      # Follow segments
      @_followAndGetKeypathSegments(@, segments, keypath)
    
    # Manually informs the observers about a change in the property with the given key.
    invalidate: (keypath, oldValue, newValue) ->
      # Call observers of keypath
      observers = @_observersByKeypath[keypath]
      if observers?
        for observer in observers
          observer(oldValue, newValue)
          
      # Call observers of computed properties which depend on this keypath
      dependentKeypaths = @_dependentKeypathsByKeypath[keypath]
      if dependentKeypaths?
        for dependentKeypath of dependentKeypaths
          @invalidate(dependentKeypath, null, null)
    
    # Registers the given observer for the given object property keypath.
    on: (keypath, observer) ->
      @_observersByKeypath[keypath] ?= []
      @_observersByKeypath[keypath].push observer
    
    # Unregisters the given observer for the given object property keypath.
    # If the observer was not registered before, this method has no effect.
    off: (keypath, observer) ->
      observers = @_observersByKeypath[keypath] 
      if observers?
        i = observers.indexOf observer
        if i != -1
          observers[i..i] = []
          
    _init: ->
      @_observersByKeypath = {}
      @_dependentKeypathsByKeypath = {}
      @_computedPropertyStack = []
     
    _setOne: (keypath, value) ->
      # Split keypath into segments
      segments = keypath.split(".")
      
      # Follow segments
      oldValue = @_followAndSetKeypathSegments(@, segments, value)
      
      # Inform observers
      @invalidate(keypath, oldValue, value)
      
      # Return old value
      oldValue
      
      
    _followAndGetKeypathSegments: (parent, segments, keypath) ->
      if segments.length == 1
        # Everything resolved. Resolve last one.
        if @_getObjectType(parent) == "observableLike"
          parent.get(segments[0])
        else
          @_invokeIfNecessary parent[segments[0]], keypath
      else
        # Still some segments left.
        if @_getObjectType(parent) == "observableLike"
          # Nested object seems to be an observable itself. We don't have to follow further, just pass the task on to it and return its value.
          parent.get(segments.join("."))
        else
          # Nested object is no observable. Follow further. Take first segment.
          firstSegment = segments.shift()
          if firstSegment of parent
            # Property is defined
            resolvedObject = @_invokeIfNecessary parent[firstSegment], keypath
            @_followAndGetKeypathSegments(resolvedObject, segments, keypath)
          else
            # Property is not defined. Dead end. Return undefined.
            undefined
    
    _followAndSetKeypathSegments: (parent, segments, value) ->
      if segments.length == 1
        # Everything resolved. Set value.
        switch @_getObjectType(parent)
          when "observableLike"
            oldValue = parent.get segments[0]
            parent.set(segments[0], value)
            oldValue
          when "mapLike", "self"
            oldValue = parent[segments[0]]
            parent[segments[0]] = value
            oldValue
          else
            # Cannot set value
            throw new Observable.SetOperationFailed(parent, segments[0], value)
      else
        # Still some segments left. 
        if @_getObjectType(parent) == "observableLike"
          # Nested object seems to be an observable itself. We don't have to follow further, just pass the task on to it and return its value.
          parent.set(segments.join("."), value)
        else
          # Nested object is no observable. Follow further. Take first segment.
          firstSegment = segments.shift()
          resolvedObject = if firstSegment of parent
            # Property is defined.
            @_invokeIfNecessary parent[firstSegment], null
          else
            # Property is not defined. Dead end. Doesn't matter. Pave the way.
            parent[firstSegment] = {}
          
          # Go on processing remaining segments by doing recursion.
          @_followAndSetKeypathSegments(resolvedObject, segments, value)
    
    _invokeIfNecessary: (obj, keypath) ->
      if typeof obj == "function"
        # Computed property
        @_computedPropertyStack.push keypath
        try
          obj.apply(@)
        finally
          @_computedPropertyStack.pop()
      else
        # Normal property
        obj
    
    _getObjectType: (obj) ->
      if obj?
        if obj == this
          "self"
        else if typeof obj.set == "function"
          "observableLike"
        else if Object.prototype.toString.call(obj) == "[object Array]"
          "array"
        else if obj instanceof Object
          "mapLike"
        else
          "other"
      else
        "nullLike"