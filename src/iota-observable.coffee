define (require) ->
  class Observable
    # Wraps the given object into an Observable
    constructor: (@observedObject) ->
      @observers = {}
    
    # Sets one or several properties of the wrapped object and informs observers.
    # TODO allow nested dot notation.
    # Can take a single map parameter or two parameters: key, value.
    set: (args...) ->
      if args.length == 1
        # A map containing new key-value pairs has been given
        properties = args[0]
        for key, value of properties
          @_internalSet(key, value)
      else
        # Two arguments, a key and a value has been given
        @_internalSet(args[0], args[1])
        
        
    # Returns the property of the wrapped object. TODO allow nested dot notation.
    get: (key) -> @observedObject[key]
    
    unset: (key) -> 
      delete @observedObject[key]
      @invalidate(key)
    
    invalidate: (key) ->
      observers = @observers[key]
      if observers?
        for callback in observers
          callback()
    
    # Registers the given observer for the given object property key.
    on: (key, callback) ->
      @observers[key] ?= []
      @observers[key].push(callback)
    
    # Unregisters the given observer for the given object property key.
    off: (key, callback) ->
      delete @observers[key]
     
    # By _ convention private
    _internalSet: (key, value) ->
      @observedObject[key] = value
      @invalidate(key)