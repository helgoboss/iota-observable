chai = require "chai"
sinon = require "sinon"
sinonChai = require "sinon-chai"
Observable = require "../iota-observable"

chai.should()
chai.use(sinonChai)

# TODO
# - add nested property support
# - add computed properties
# - add dependency watching
# - add observer parameters (old/new)

## Reused stuff

# Creates reused tests
createTests = (description, createObservable) ->
  describe description, ->
    o = null
    
    beforeEach -> 
      o = createObservable()
      
    it "should return property values using get", ->  
      o.get("foo").should.equal 1
      
    it "should return nested property values using get", ->  
      o.get("nested.bum").should.equal 3
      
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
      o.set("bar", 3)
      o.get("bar").should.equal 3
      
    it "should set nested property values using set", ->
      o.set("nested.baz", 7)
      o.get("nested.baz").should.equal 7
      
    it "should set property values using set with a map", ->
      o.set
        foo: 3
        bar: 4
        
      o.get("foo").should.equal 3
      o.get("bar").should.equal 4
          
    it "should call registered observers when setting a property value via set", ->
      callback = sinon.spy()
      o.on "foo", callback
      
      o.set
        foo: 3

      callback.should.have.been.called
      
    it "should call registered observers when setting a new property value via set", ->
      callback = sinon.spy()
      o.on "newProp", callback
      
      o.set
        newProp: 3

      callback.should.have.been.called
      
    it "should call registered observers when setting a nested property value via set", ->
      callback = sinon.spy()
      o.on "nested.baz", callback
      
      o.set("nested.baz", 3)

      callback.should.have.been.called
      
    it "should also call registered observers of nested observable when setting a nested property value via set", ->
      nestedObservable = new Observable
        observedProp: 2
      o.nested.observableObj = nestedObservable
        
      nestedCallback = sinon.spy()
      callback = sinon.spy()
        
      nestedObservable.on "observedProp", nestedCallback
      o.on "nested.observableObj.observedProp", callback
      
      o.set("nested.observableObj.observedProp", 3)

      callback.should.have.been.called
      nestedCallback.should.have.been.called
      
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
  nested:
    bum: 3
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
createTests "An object which has been made observable", makeObservable
    

  
  
