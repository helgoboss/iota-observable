# See "amdefine" on github
`if (typeof define !== 'function') { var define = require('amdefine')(module) }`

define (require) ->
  class Observable
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
    # Returns whether it could set the value. It cannot set the value if
    # it stumbles upon a defined property whose type is not map-like.
    # If multiple properties are set, returns and array of booleans.
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
      
      # Follow segments
      @_followAndGetKeypathSegments(@, segments)
    
    # Manually informs the observers about a change in the property with the given key.
    invalidate: (keypath) ->
      observers = @_observersByKeypath[keypath]
      if observers?
        for observer in observers 
          observer()
    
    # Registers the given observer for the given object property keypath.
    on: (keypath, observer) ->
      @_observersByKeypath[keypath] ?= []
      @_observersByKeypath[keypath].push(observer)
    
    # Unregisters the given observer for the given object property keypath.
    off: (keypath, observer) ->
      os = @_observersByKeypath[keypath] 
      if os?
        i = os.indexOf(observer)
        if i != -1
          os[i..i] = []
          
    _init: ->
      @_observersByKeypath = {}
     
    _setOne: (keypath, value) ->
      # Split keypath into segments
      segments = keypath.split(".")
      
      # Follow segments
      successful = @_followAndSetKeypathSegments(@, segments, value)
      
      if successful
        @invalidate(keypath)
        
      successful
      
    _followAndGetKeypathSegments: (parent, segments) ->
      if segments.length == 1
        # Everything resolved. Resolve last one.
        if @_getObjectType(parent) == "observableLike"
          parent.get(segments[0])
        else
          parent[segments[0]]
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
            resolvedObject = parent[firstSegment]
            @_followAndGetKeypathSegments(resolvedObject, segments)
          else
            # Property is not defined. Dead end. Return undefined.
            undefined
    
    _followAndSetKeypathSegments: (parent, segments, value) ->
      if segments.length == 1
        # Everything resolved. Set value.
        switch @_getObjectType(parent)
          when "observableLike"
            parent.set(segments[0], value)
            true
          when "mapLike", "self"
            parent[segments[0]] = value
            true
          else
            # Cannot set value
            false
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
            parent[firstSegment]
          else
            # Property is not defined. Dead end. Doesn't matter. Pave the way.
            parent[firstSegment] = {}
          
          # Go on processing remaining segments by doing recursion.
          @_followAndSetKeypathSegments(resolvedObject, segments, value)
    
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