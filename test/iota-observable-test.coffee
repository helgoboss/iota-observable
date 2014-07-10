chai = require "chai"
sinon = require "sinon"
sinonChai = require "sinon-chai"
Observable = require "../iota-observable"

should = chai.should()
chai.use(sinonChai)

# TODO
# - Implement throttled observer invocations
# - add dependency old/new

## Reused stuff

# Creates reused tests
createTests = (description, createObservable) ->
  describe description, ->
    o = null
    
    beforeEach -> 
      o = createObservable()
      
    it "should return property values using get", ->  
      o.get("foo").should.equal 1
      
    it "should return computed property values using get", ->  
      o.get("computed").should.equal 77
      
    it "should return dependent computed property values using get", ->  
      o.get("dependentComputed").should.equal 72

    it "should return nested property values using get", ->  
      o.get("nested.bum").should.equal 3
      
    it "should return nested computed property values using get", ->  
      o.get("computedNested.computed2").should.equal 22
      
    it "should return nested observable property values using get", ->  
      o.get("nested.observableObj.observedProp").should.equal 7
      
    it "should return undefined when it meets a dead end or incompatible property using get", ->  
      result = o.get("nested.bum.olli")
      should.equal(result, undefined)
      
    it "should return property values using dot operator", ->  
      o.foo.should.equal 1
      
    it "should return nested property values using dot operator", ->  
      o.nested.bum.should.equal 3

    it "should set property values using dot operator", ->
      o.bar = 3
      o.get("bar").should.equal 3
      
    it "should set nested property values using dot operator", ->
      o.nested.baz = 7
      o.get("nested.baz").should.equal 7

    it "should set property values using set", ->
      o.set("bar", 3).should.equal 2
      o.get("bar").should.equal 3
      
    it "should set nested property values using set", ->
      oldValue = o.set("nested.baz", 7)
      should.equal(oldValue, undefined)
      o.get("nested.baz").should.equal 7
      
    it "should set nested observable property values using set", ->
      o.set("nested.observableObj.observedProp", 8).should.equal 7
      o.get("nested.observableObj.observedProp").should.equal 8
      
    it "should pave the way when it meets a dead end using set", ->
      oldValue = o.set("nested.hui.super", 7)
      should.equal(oldValue, undefined)
      o.get("nested.hui.super").should.equal 7
      
    it "shouldn't pave the way when it meets an incompatible property using set", ->
      f = -> o.set("nested.bum.super", 7)
      should.Throw(f, Observable.SetFailed)
      
    it "should set property values using set with a map", ->
      [fooSuccessful, barSuccessful] = o.set
        foo: 3
        bar: 4
        
      fooSuccessful.should.equal 1
      barSuccessful.should.equal 2
      o.get("foo").should.equal 3
      o.get("bar").should.equal 4
          
    it "should call registered observers when calling invalidate for a property", ->
      callback = sinon.spy()
      o.on "foo", callback
      
      o.invalidate("foo")

      callback.should.have.been.calledOnce
      
    it "should call registered observers with old and new value when setting a property value via set", ->
      callback = sinon.spy()
      o.on "foo", callback
      
      o.set
        foo: 3

      callback.should.have.been.calledWith("foo", 1, 3)

    it "should call registered observers on each two-arguments set invocation", ->
      callback = sinon.spy()
      o.on "foo", callback
      
      o.set("foo", 3)
      o.set("foo", 3)

      callback.should.have.been.calledTwice
      
    it "shouldn't call observers within a batch", ->
      callback = sinon.spy()
      o.on "foo", callback
      
      o.beginBatch()
      o.set("foo", 3)
      callback.should.not.have.been.called
      o.endBatch()
      
      callback.should.have.been.calledOnce
      
    it "should call observers for each invalidated property only once after ending batch", ->
      callback = sinon.spy()
      o.on "foo", callback
      
      o.beginBatch()
      o.set("foo", 3)
      o.set("foo", 3)
      o.endBatch()
      
      callback.should.have.been.calledOnce
      
      

    it "should not call observers for each invalidated property if ending batch with flag set", ->
      callback = sinon.spy()
      o.on "foo", callback

      o.beginBatch()
      o.set("foo", 3)
      o.set("foo", 3)
      o.endBatch(true)

      callback.should.not.have.been.calledOnce

    it "should call registered observers of a computed property when setting a dependency of the computed property via set", ->
      o.get("x").should.equal 72
      
      callback = sinon.spy()
      o.on "x", callback
      
      o.set
        bar: 3

      o.get("x").should.equal 73
      callback.should.have.been.called
      
      
    it "should call registered observers of a computed property y which depends on another computed property x when setting a dependency of the computed property (bar) via set", ->
      o.get("y").should.equal 74
      
      callback = sinon.spy()
      o.on "y", callback
      
      o.set
        bar: 3

      o.get("y").should.equal 75
      callback.should.have.been.calledOnce
      
    it "should call registered observers of x as well", ->
      o.get("y").should.equal 74
      
      callback = sinon.spy()
      o.on "x", callback
      
      o.set
        bar: 3

      o.get("x").should.equal 73
      callback.should.have.been.calledOnce
      
    it "should call observers the correct number of times even in more complicated dependency scenarios", ->
      o.get("z").should.equal 73
      
      callbackX = sinon.spy()
      callbackZ = sinon.spy()
      
      o.on "x", callbackX
      o.on "z", callbackZ
      
      o.set
        bar: 3
        
      o.get("x").should.equal 73
      o.get("z").should.equal 74
        
      o.set
        foo: 2

      o.get("x").should.equal 73
      o.get("z").should.equal 75
      
      callbackX.should.have.been.calledOnce # because x depends on bar only
      callbackZ.should.have.been.calledTwice # because z depends on both bar and foo
      
    it "should call each observer for each changed property only once with computed properties", ->
      # Query computed property at least once so dependencies are tracked
      o.get("diamond")
      
      callback = sinon.spy()
      o.on "diamond", callback
      
      o.set
        bar: 3
      
      # A less-than-optimal implementation might call the observer of the computed property 
      # "diamond" two times because both of its dependencies have changed
      callback.should.have.been.calledOnce 
      
    it "should call each observer for each changed property only once when calling set with a map (atomic set operation)", ->
      # Query computed property at least once so dependencies are tracked
      o.get("z")
      
      callback = sinon.spy()
      
      o.on "z", callback
      
      o.set
        bar: 3
        foo: 2
      
      callback.should.have.been.calledOnce 
      
    it "should not consider implicit dependency observers for the same keypath as equal", ->
      # If x changes, both y and z observers should be informed
      o.get("x").should.equal 72
      o.get("y").should.equal 74
      o.get("z").should.equal 73
      
      callbackX = sinon.spy()
      callbackY = sinon.spy()
      callbackZ = sinon.spy()
      
      o.on "x", callbackX
      o.on "y", callbackY
      o.on "z", callbackZ
      
      o.set
        bar: 3
        
      o.get("x").should.equal 73
      o.get("y").should.equal 75
      o.get("z").should.equal 74
      
      callbackX.should.have.been.calledOnce # because x depends on bar only
      callbackY.should.have.been.calledOnce # because x depends on bar only
      callbackZ.should.have.been.calledOnce # because z depends on both bar and foo
      
      
    it "should call registered observers with undefined and new value when setting a new property value via set", ->
      callback = sinon.spy()
      o.on "newProp", callback
      
      o.set
        newProp: 3

      callback.should.have.been.calledWith("newProp", undefined, 3)
      
    it "should call registered observers when setting a nested property value via set", ->
      callback = sinon.spy()
      o.on "nested.baz", callback
      
      o.set("nested.baz", 3)

      callback.should.have.been.calledWith("nested.baz", undefined, 3)
      
    it "should also call registered observers of last nested observable when setting a nested property value via set", ->
      nestedCallback = sinon.spy()
      callback = sinon.spy()
        
      o.nested.observableObj.on "observedProp", nestedCallback
      o.on "nested.observableObj.observedProp", callback
      
      o.set("nested.observableObj.observedProp", 3)

      callback.should.have.been.calledWith("nested.observableObj.observedProp", 7, 3)
      nestedCallback.should.have.been.calledWith("observedProp", 7, 3)
      
    it "should also call registered observers of middle nested observable when setting a nested property value via set", ->
      nestedCallback = sinon.spy()
      callback = sinon.spy()
        
      o.nested.observableObj.on "observableObj2.observedProp2", nestedCallback
      o.on "nested.observableObj.observableObj2.observedProp2", callback
      
      o.set("nested.observableObj.observableObj2.observedProp2", 3)

      callback.should.have.been.calledWith("nested.observableObj.observableObj2.observedProp2", 8, 3)
      nestedCallback.should.have.been.calledWith("observableObj2.observedProp2", 8, 3)
      
    it "should not call unregistered observers when setting a property value via set", ->
      callback = sinon.spy()
      o.on "foo", callback
      o.off "foo", callback
      
      o.set
        foo: 3

      callback.should.not.have.been.called
      
    it "should not call unregistered observers when setting a nested property value via set", ->
      callback = sinon.spy()
      o.on "nested.baz", callback
      o.off "nested.baz", callback
      
      o.set("nested.baz", 3)

      callback.should.not.have.been.called


# Creates reused data
createData = ->
  foo: 1
  bar: 2
  computed: -> 77
  dependentComputed: -> @bar + 70
  x: -> @get("bar") + 70
  y: -> @get("x") + 2
  z: -> @get("x") + @get("foo")
  diamond: -> @get("x") + @get("z")
  computedNested: ->
    computed2: -> 22
  nested:
    bum: 3
    observableObj: new Observable
      observedProp: 7
      observableObj2: new Observable
        observedProp2: 8 
    nested2:
      baw: 4
  
# Instantiates an Observable
instantiateObservable = ->
  new Observable(createData())
  
# Makes an existing object observable
makeObservable = ->
  o = createData()
  Observable.makeObservable(o)
  o
  

## Tests

describe "Observable", ->
  it "should be a class whose constructor is okay with getting no arguments", ->
    o = new Observable
    
  it "should be a class whose constructor copies a given object's properties", ->
    instantiateObservable()
    
  it "should let you make existing objects observable", ->
    makeObservable()
    

createTests "An Observable instance", instantiateObservable
# createTests "An Observable instance", makeObservable