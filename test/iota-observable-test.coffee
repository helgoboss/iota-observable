chai = require "chai"
sinon = require "sinon"
sinonChai = require "sinon-chai"
Observable = require "../iota-observable"

chai.should()
chai.use(sinonChai)

describe "A mixed in observable", ->
  o = null
  
  beforeEach ->
    # We are going to apply the Observable mixin to following object
    o = 
      foo: 1
      bar: 2
    
    # Apply mixin
    for key, value of Observable
      o[key] = value
    
  it "should return property values using get", ->  
    o.get("foo").should.equal 1
    
  it "should return property values using dot operator", ->  
    o.foo.should.equal 1

  it "should set property values using dot operator", ->
    o.bar = 3
    o.get("bar").should.equal 3

  it "should set property values using set with 2 arguments", ->
    o.set("bar", 3)
    o.get("bar").should.equal 3
    
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
    
  it "should not call unregistered observers when setting a property value via set", ->
    callback = sinon.spy()
    o.on "foo", callback
    o.off "foo", callback
    
    o.set
      foo: 3

    callback.should.not.have.been.called