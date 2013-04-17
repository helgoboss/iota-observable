Iota Observable
===============

Iota Observable is a tiny library written in the programming language [CoffeeScript](http://coffeescript.org/). It offers functions to create observable objects and make existing objects observable. Its primary use case is to be employed as part of a view layer with [declarative data-binding](http://en.wikipedia.org/wiki/Data_binding) in a [single page app](http://en.wikipedia.org/wiki/Single-page_application). Because CoffeeScript compiles to [JavaScript](http://en.wikipedia.org/wiki/JavaScript), you can use it with JavaScript as well.

Iota Observable has been designed to play nicely with [Rivets](http://github.com/mikeric/rivets), a little template engine with declarative data binding from [Michael Richards](https://github.com/mikeric). Both libraries strive to "do one thing and do it well". They leave everything else to your choice &mdash; a modular approach. You might want to give the "Rivets & Iota Observable combo" a chance if you feel [AngularJS](http://angularjs.org/), [EmberJS](http://emberjs.com/), [Knockout](http://knockoutjs.com/) etc. are too invasive and big for your use case.

## Examples

For JavaScript examples, please visit the [project website](http://www.helgoboss.org/projects/iota-observable/).

### Basics (CoffeeScript)

```coffeescript
# Extend from Observable
class Person extends Observable
  constructor: (@firstName, @lastName) ->
  name: -> 
    @get('firstName') + ' ' + @get('lastName')

obj = new Person "Bela", "Bartok"

# Register observer
obj.on 'name', -> console.log("Name has changed")

# Change property value, prints "Name has changed"
obj.set 'firstName', 'Béla'
```

### With Rivets (CoffeeScript)

Needs [jQuery](http://jquery.com/) and [Rivets Iota Observable Adapter](http://github.com/helgoboss/rivets-iota-observable-adapter).

```coffeescript
# Create counter object, mix in Observable
model =
  counter: Observable.makeObservable
    value: 5

# Bind counter value to a DOM element
template = '&lt;div data-text="counter.value" /&gt;'
domElement = $(template)[0]
rivets.bind(domElement, model)
```

## Further reading

Learn more on the [project website](http://www.helgoboss.org/projects/iota-observable/).
