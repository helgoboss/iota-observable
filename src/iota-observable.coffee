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
    # Can take a single map parameter or two parameters: key, value.
    set: (args...) ->
      if args.length == 1
        # A map containing new key-value pairs has been given
        properties = args[0]
        for key, value of properties
          @_setOne(key, value)
      else
        # Two arguments (a key and a value) have been given
        @_setOne(args[0], args[1])
        
        
    # Returns the property with the given key.
    get: (key) ->
      result = @_processKeypath(key)
      if result.resolvedParent?
        result.resolvedParent[result.lastSegment]
      else
        undefined
    
    # Manually informs the observers about a change in the property with the given key.
    invalidate: (key) ->
      observers = @_observersByKey[key]
      if observers?
        for observer in observers 
          observer()
    
    # Registers the given observer for the given object property key.
    on: (key, observer) ->
      @_observersByKey[key] ?= []
      @_observersByKey[key].push(observer)
    
    # Unregisters the given observer for the given object property key.
    off: (key, observer) ->
      os = @_observersByKey[key] 
      if os?
        i = os.indexOf(observer)
        if i != -1
          os[i..i] = []
          
    _init: ->
      @_observersByKey = {}
     
    _setOne: (key, value) ->
      result = @_processKeypath(key)
      if result.resolvedParent?
        result.resolvedParent[result.lastSegment] = value
        @invalidate(key)
      
    _processKeypath: (keypath) ->
      # Split keypath into segments
      segments = keypath.split(".")
      
      # Process segments
      @_processKeypathSegments(@, segments)
      
    _processKeypathSegments: (parent, segments) ->
      if segments.length == 1
        # Everything resolved
        resolvedParent: parent
        lastSegment: segments[0]
      else
        # Still some segments left. Remove first one.
        firstSegment = segments.shift()
        
        # Lookup object
        resolvedObject = parent[firstSegment]
        
        # Go on processing remaining segments by doing recursion
        @_processKeypathSegments(resolvedObject, segments)