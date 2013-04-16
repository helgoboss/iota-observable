Iota Observable
===============

Iota Observable is a tiny library written in the programming language [CoffeeScript](http://coffeescript.org/). It offers functions to create observable objects and make existing objects observable. Its primary use case is to be employed as part of a view layer with [declarative data-binding](http://en.wikipedia.org/wiki/Data_binding) in a JavaScript [single page app](http://en.wikipedia.org/wiki/Single-pageapplication). Because CoffeeScript compiles to [JavaScript](http://en.wikipedia.org/wiki/JavaScript), you can use it with JavaScript as well.

Iota Observable has been designed to play nicely with [Rivets](http://github.com/mikeric/rivets), a little template engine with declarative data binding from [Michael Richards](https://github.com/mikeric). Both libraries strive to "do one thing and do it well". They leave everything else to your choice &mdash; a modular approach. You might want to give the Rivets & Iota Observable combo a chance if you feel that [AngularJS](http://angularjs.org/), [EmberJS](http://emberjs.com/), [Knockout](http://knockoutjs.com/), [Batman](http://batmanjs.org/) etc. are too invasive and big for your use case.

## Examples

For JavaScript examples, please visit the [project website](http://www.helgoboss.org/projects/iota-observable/).

### Basics (CoffeeScript)

```coffeescript
# Extend from Observable
class Person extends Observable
  constructor: (@firstName, @lastName) ->
  name: -> 
    @get('firstName') + ' ' + @get('lastName')

# Create a person
obj = new Person "Bela", "Bartók"

# Register observer
obj.on 'name', -> console.log("Name has changed")

# Change property value, prints "Name has changed"
obj.set 'firstName', 'Béla'
```

### With Rivets (CoffeeScript)

Needs [jQuery](http://jquery.com/) and [Iota Rivets Observable Adapter](http://github.com/helgoboss/iota-rivets-observable-adapter).

```coffeescript
# Create counter object, make raw object Observable
model =
  counter: Observable.makeObservable
    value: 5

# Bind counter value to a DOM element
# (needs jQuery and iota-rivets-observable-adapter)
template = '<div data-text="counter.value" />'
domElement = $(template)[0]
rivets.bind(domElement, model)
```

## Further reading

Learn more on the [project website](http://www.helgoboss.org/projects/iota-observable/).
