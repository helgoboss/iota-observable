if typeof define isnt "function"
  define = require("amdefine")(module)

define (require) ->
  Observable =
    # Sets one or several properties of this object and informs observers.
    # Can take a single map parameter or two parameters: key, value.
    # TODO allow nested dot notation.
    set: (args...) ->
      if args.length == 1
        # A map containing new key-value pairs has been given
        properties = args[0]
        for key, value of properties
          @_setOne(key, value)
      else
        # Two arguments (a key and a value) have been given
        @_setOne(args[0], args[1])
        
        
    # Returns the property with the given key. TODO allow nested dot notation.
    get: (key) -> 
      @[key]
    
    # Manually informs the observers about a change in the property with the given key.
    invalidate: (key) ->
      observers = @_getObserversByKey()[key]
      if observers?
        for observer in observers 
          observer()
    
    # Registers the given observer for the given object property key.
    on: (key, observer) ->
      @_getObserversByKey()[key] ?= []
      @_getObserversByKey()[key].push(observer)
    
    # Unregisters the given observer for the given object property key.
    off: (key, observer) ->
      os = @_getObserversByKey()[key] 
      if os?
        i = os.indexOf(observer)
        if i != -1
          os[i..i] = []
     
    _setOne: (key, value) ->
      @[key] = value
      @invalidate(key)
      
    _getObserversByKey: ->
      @_observersByKey ?= {}