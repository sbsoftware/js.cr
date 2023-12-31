# `js.cr`

An experimental tool to generate JavaScript code from Crystal code.

## Contents

* [Goals](#goals)
* [Examples](#examples)
  * [Code Snippets](#javascript-code)
    * [`_call`](#_call)
  * [Functions](#javascript-functions)
  * [Classes](#javascript-classes)
  * [Files](#javascript-files)
    * [Aliases](#aliases)
  * [Modules](#javascript-modules)
  * [Loops](#loops)

## Goals

The most important idea behind this project is to create the ability to reference JavaScript functions, classes and modules in Cystal code using typechecked entities instead of strings.

Initially I wanted to leverage Crystal's type system to have my JavaScript code typechecked at compile time, but that turned out to be too much to start with. It remains a goal to reintroduce that feature at some point, but for now you can generate _invalid_ JavaScript with this library.

Please note that this is still very experimental and probably lacks essential features to be genuinely used. So far I am employing it to generate stimulus controllers which toggle some classes of HTML elements.

Also, I skipped any whitespacing for now as I wanted to have my proof of concept as fast as possible. Not sure if I will ever deem it necessary to add it. The specs are still quite readable because I include whitespace in the examples and only remove it before comparing to the results.

## Examples

### JavaScript Code

Just want to output some loose snippet of JavaScript code? Use the `JS::Code` base class. You can print your code directly into a `<script>` tag of your favorite template engine via `.to_js` if you want.

```crystal
require "js"

class MyCode < JS::Code
  def_to_js do
    console.log("Hello World!")
  end
end

puts MyCode.to_js
```

#### `_call`

In Crystal, there are no object properties but just method calls. Without any type information about the JS code you are calling, `js.cr` cannot know whether you want to reference a property or call a function without any arguments on an object.
It therefore always assumes a property reference. If you need a function call instead, just append `._call` to it.
Note that this isn't necessary if your call has arguments.

```crystal
require "js"

class MyCallCode < JS::Code
  def_to_js do
    a = SomeUnknownJSConstant.somePropertyOfIt
    b = SomeUnknownJSConstant.someFunctionOfIt._call
    c = SomeUnknownJSConstant.someOtherFunctionOfIt("foo")
  end
end

# => var a = SomeUnknownJSConstant.somePropertyOfIt;
# => var b = SomeUnknownJSConstant.someFunctionOfIt();
# => var c = SomeUnknownJSConstant.someOtherFunctionOfIt("foo");
puts MyCallCode.to_js
```

### JavaScript Functions

If you were wondering how to define a function within `JS::Code.def_to_js` - that's not possible. Well, technically it is via a `_literal_js` call but that's dirty and there is a better way:

```crystal
require "js"

class MyFunction < JS::Function
  def_to_js do |foo|
    console.log(foo)
  end
end

puts MyFunction.to_js
```

You _could_ have that printed into a `<script>` tag again via `.to_js` and reference it in an `onclick` attribute by calling `.to_js_call`. Not sure how hip that is anymore.

```ecr
<html>
  <head>
    <title>JavaScript!</title>
    <script><%= MyFunction.to_js %></script>
  </head>
  <body>
    <div onclick="<%= MyFunction.to_js_call("test") %>">Print "test" to the console!</div>
  </body>
</html>
```

### JavaScript Classes

Generate modern [JavaScript Classes](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes) with the `JS::Class` base class. Classes have `methods` instead of `functions`.

```crystal
require "js"

class MyClass < JS::Class
  js_method :do_something do
    console.log("test")
  end
end

puts MyClass.to_js
```

### Javascript Files

Want to put some functions and classes together? A `JS::File` encapsulates an arbitrary number of these, along with one code snippet to use them. This might change in the future, but it's enough for now.

```crystal
require "js"

class MyFile < JS::File
  js_function :say_hello do
    console.log("Hello!")
  end

  js_class ImportantData do
    js_method :constructor do |name|
      this.name = name
    end

    js_method :tell_name do
      console.log(this.name)
    end
  end

  def_to_js do
    say_hello.to_js_call
    my_data = ImportantData.new("Joe")
    my_data.tell_name._call
  end
end

puts MyFile.to_js
```

#### Aliases

Sometimes you want to leverage JS libraries like jQuery or underscore.js that define entry points not expressable in Crystal. For these cases you can define aliases.

```crystal
require "js"

class MyAliasingFile < JS::File
  js_alias "jQ", "$"

  def_to_js do
    jQ("div").addClass("foo")
  end
end

puts MyAliasingFile.to_js
```

### JavaScript Modules

All hail [JavaScript Modules](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules)! Here these are just `JS::File`s that can additionally `import` things.

Please note that for now there will be no typechecks whatsoever by the Crystal compiler for this. You only need to include `import` statements for them to be present in the JavaScript code.

```crystal
require "js"

class MyImportingModule < JS::Module
  js_import Application, Controller, from: "/assets/stimulus.js"

  js_class MyStimulusController do
    js_method :connect do
      console.log("connected!")
    end
  end

  def_to_js do
    window.Stimulus = Application.start._call

    Stimulus.register("my-stimulus", MyStimulusController)
  end
end

puts MyImportingModule.to_js
```

### Loops

`forEach` loops are supported.

```crystal
require "js"

class MyLoop < JS::Code
  def_to_js do
    values = ["This", "Is", "Sparta"]
    values.forEach do |value|
      console.log(value)
    end
  end
end

puts MyLoop.to_js
```
