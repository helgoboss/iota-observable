class Observable
  ###
  An object which notifies observers whenever a property is changed using `set`.
  ###
  
  @SetOperationFailed: class extends Error
    ###
    Error thrown if a property value could not be set.
    ###
    constructor: (obj, key, value) ->
      @message = "Setting [#{key}] to [#{value}] on [#{obj}] failed"
  
  @makeObservable: (obj) ->
    ###
    Makes the given object `obj` observable by copying all `Observable` methods to it and initializing the `Observable`'s state.
    ###
    # Copy Observable's prototype properties to the object
    for key, value of @::
      obj[key] = value
      
    # Initialize object
    obj._init()
  
  constructor: (obj) ->
    ###
    Initializes the Observable. If `obj` is given, all its properties are copied into the new `Observable`.
    ###
    # Initialize
    @_init()
    
    # Copy properties of obj
    if obj?
      for key, value of obj
        @[key] = value

  set: (args...) ->
    ###
    Sets the values of one or several properties of this object or nested objects and informs observers.
    
    If a single argument is passed, it is assumed to be an object containing keypath-value pairs. If two arguments 
    are passed, the first one is interpreted as the keypath and the second one as the value.
    
    The property is identified by its keypath using the dot notation. The implementation follows the keypath 
    and sets the referenced property to the given value. If it meets a dead end on the path (an object which 
    doesn't contain the property which comes next on the keypath), it just creates an empty object and continues 
    with the rest of the keypath. If it cannot set the value because it stumbles upon a defined property whose type is 
    not an object, it throws an `Observable.SetOperationFailed` error.
    
    Returns the old value or `undefined` if there was none. If multiple properties are set, returns and array of old values. 
    ###
    
    batchStarted = @beginBatch()
    
    oldValue = if args.length == 1
      # A map containing new keypath-value pairs has been given
      properties = args[0]
      for keypath, value of properties
        @_setOne(keypath, value)
    else
      # Two arguments (a keypath and a value) have been given
      @_setOne(args[0], args[1])
      
    if batchStarted
      @endBatch()
      
    oldValue
      
  
  get: (keypath) ->
    ### 
    Returns the property identified by the given keypath.
    
    Also handles computed properties by evaluating them. If other properties are queried using `get` during the evaluation of the
    computed property, their dependencies are tracked.
    ###
    
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
  
  invalidate: (keypath, oldValue, newValue) ->
    ###
    Manually informs the observers about a change in the property with the given keypath. This is for example necessary
    when dealing with changes in array properties.
    
    Delays the notification if a batch is active until `endBatch` is called.
    ###
    batchStarted = @beginBatch()
    
    # Memorize keypath so its observers can be informed later, after the batch has been ended
    if keypath of @_invalidationByKeypath
      # There's already an invalidation for that keypath. Just replace its newValue.
      @_invalidationByKeypath[keypath].newValue = newValue
    else
      # There's no invalidation for that keypath yet.
      @_invalidationByKeypath[keypath] =
        oldValue: oldValue
        newValue: newValue
    
    # Invalidate computed properties which depend on this keypath
    dependentKeypaths = @_dependentKeypathsByKeypath[keypath]
    if dependentKeypaths?
      for dependentKeypath of dependentKeypaths
        @invalidate(dependentKeypath, null, null)
        
    if batchStarted
      @endBatch()
  
  
  on: (keypath, observer) ->
    ### 
    Registers the given observer for the given object property keypath.
    ###
    @_observersByKeypath[keypath] ?= []
    @_observersByKeypath[keypath].push observer
  
  off: (keypath, observer) ->
    ### 
    Unregisters the given observer for the given object property keypath.
    
    If the observer was not registered before, this method has no effect.
    ###
    observers = @_observersByKeypath[keypath] 
    if observers?
      i = observers.indexOf observer
      if i != -1
        observers[i..i] = []
       
  beginBatch: -> 
    ###
    Starts a batch. 
    
    Within a batch, observers are not notified of changes. They will be notified as soon as `endBatch` is called.
    
    If a batch was already active, the method has no effect and returns false.
    ###
    if @_inBatch
      false
    else
      @_inBatch = true
      true
  
  endBatch: ->
    ###
    Ends the batch and carries out the delayed observer notifications.
    
    If no batch was active, the method has no effect and returns false.
    ###
    if @_inBatch
      @_inBatch = false
      
      # Call observers of keypath. Make for each keypath-observer combination exactly one call.
      for keypath, invalidation of @_invalidationByKeypath
        observers = @_observersByKeypath[keypath]
        if observers?
          for observer in observers
            observer(keypath, invalidation.oldValue, invalidation.newValue)
        
        # Remove invalidation
        delete @_invalidationByKeypath[keypath]
      true
    else
      false
    
        
  _init: ->
    @_observersByKeypath = {}
    @_dependentKeypathsByKeypath = {}
    @_computedPropertyStack = []
    @_inBatch = false
    @_invalidationByKeypath = {}
   
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