## rux [![Build Status](https://travis-ci.com/camertron/rux.svg?branch=master)](https://travis-ci.com/camertron/rux)

Rux is a JSX-inspired way to write HTML tags in your Ruby code. It can be used to render view components in Rails via the [rux-rails gem](https://github.com/camertron/rux-rails). This repo however contains only the rux parser itself.

## Introduction

A bit of background before we dive into how to use rux.

### React and JSX

React mainstreamed the idea of composing websites from a series of components. To make it conceptually easier to transition from HTML templates to Javascript components, React also introduced an HTML-based syntax called JSX that allows developers to embed HTML into their Javascript code.

### Rails View Components

For a long time, Rails didn't really have any support for components, preferring to rely on HTML template languages like ERB and HAML. The fine folks at Github however decided components could work well in Rails and released their [view_component framework](https://github.com/github/view_component). There was even some talk about merging view_component into Rails core as `ActionView::Component`, but unfortunately it looks like that won't be happening.

**NOTE**: I'm going to be focusing on Rails examples here using the view_component gem, but rendering views from a series of components is a framework-agnostic idea.

### View Component Example

A view component is just a class. The actual view portion is usually stored in a secondary template file that the component renders in the context of an instance of that class. For example, here's a very basic view component that displays a person's name on the page:

```ruby
# app/components/name_component.rb
class NameComponent < ViewComponent::Base
  def initialize(first_name:, last_name:)
    @first_name = first_name
    @last_name = last_name
  end
end
```

```html+erb
<%# app/components/name_component.html.erb %>
<span><%= @first_name %> <%= last_name %></span>
```

View components have a number of very nice properties. Read about them on [viewcomponent.org](https://viewcomponent.org/) or watch Joel Hawksley's excellent 2019 [Railsconf talk](https://www.youtube.com/watch?v=y5Z5a6QdA-M).

## HTML in Your Ruby

Rux does one thing: it lets you write HTML in your Ruby code. Here's the name component example from earlier rewritten in rux (sorry about the syntax highlighting, Github doesn't know about rux yet).

```ruby
# app/components/name_component.rux
class NameComponent < ViewComponent::Base
  def initialize(first_name:, last_name:)
    @first_name = first_name
    @last_name = last_name
  end

  def call
    <span>
      {@first_name} {@last_name}
    </span>
  end
end
```

**NOTE**: The example above takes advantage of a feature of the view_component gem that lets you define a `call` method instead of creating a separate template file.

Next, we'll run the `ruxc` tool to translate the rux code into Ruby code, eg. `ruxc app/components/name_component.rux`. Here's the result:

```ruby
class NameComponent < ViewComponent::Base
  def initialize(first_name:, last_name:)
    @first_name = first_name
    @last_name = last_name
  end

  def call
    Rux.tag("span") {
      Rux.create_buffer.tap { |_rux_buf_,|
        _rux_buf_ << @first_name
        _rux_buf_ << " "
        _rux_buf_ << @last_name
      }.to_s
    }
  end
end
```

As you can see, the span tag was converted to a `Rux.tag` call. The instance variables containing the first and last names are concatenated together and rendered inside the span.

## Composing Components

Things get even more interesting when it comes to rendering components inside other components. Let's create a greeting component that makes use of the name component:

```ruby
# app/components/greeting_component.rux
class GreetingComponent < ViewComponent::Base
  def call
    <div>
      Hey there <NameComponent first-name="Homer" last-name="Simpson" />!
    </div>
  end
end
```

The `ruxc` tool produces:

```ruby
class GreetingComponent < ViewComponent::Base
  def call
    Rux.tag("div") {
      Rux.create_buffer.tap { |_rux_buf_,|
        _rux_buf_ << " Hey there "
        _rux_buf_ << render(NameComponent.new(first_name: "Homer", last_name: "Simpson"))
        _rux_buf_ << "! "
      }.to_s
    }
  end
end
```

The `<NameComponent>` tag was translated into an instance of the `NameComponent` class and the attributes into its keyword arguments.

**NOTE**: The `render` method is provided by `ViewComponent::Base`.

## Embedding Ruby

Since rux code is translated into Ruby code, anything goes. You're free to put any valid Ruby statements inside the curly braces.

For example, let's say we want to change our greeting component to greet a variable number of people:

```ruby
# app/components/greeting_component.rux
class GreetingComponent < ViewComponent::Base
  def initialize(people:)
    # people is an array of hashes containing :first_name and :last_name keys
    @people = people
  end

  def call
    <div>
      {@people.map do |person|
        <NameComponent
          first-name={person[:first_name]}
          last-name={person[:last_name]}
        />
      end}
    </div>
  end
end
```

Notice we were able to embed Ruby within rux within Ruby within rux. Within Ruby. The rux parser supports unlimited levels of nesting, although you'll probably not want to go _too_ crazy.

## Keyword Arguments Only

Any view component that will be rendered by rux must _only_ accept keyword arguments in its constructor. For example:

```ruby
class MyComponent < ViewComponent::Base
  # GOOD
  def initialize(first_name:, last_name:)
  end

  # BAD
  def initialize(first_name, last_name)
  end

  # BAD
  def initialize(first_name, last_name = 'Simpson')
  end
end
```

In other words, positional arguments are not allowed. This is because there's no such thing as a positional HTML attribute - all HTML attributes are key/value pairs. So, in order to match up with HTML, rux components are written with keyword arguments.

## How it Works

Translating rux code (Ruby + HTML tags) into Ruby code happens in three phases: lexing, parsing, and emitting. The lexer phase is implemented as a wrapper around the lexer from the [Parser gem](https://github.com/whitequark/parser) that looks for specific patterns in the token stream. When it finds an opening HTML tag, it hands off lexing to the rux lexer. When the tag ends, the lexer continues emitting Ruby tokens, and so on.

In the parsing phase, the token stream is transformed into an intermediate representation of the code known as an abstract syntax tree, or AST. It's the parser's job to work out which tags are children of other tags, associate attributes with tags, etc.

Finally it's time to generate Ruby code in the emitting phase. The rux gem makes use of the visitor pattern to walk over all the nodes in the AST and generate a big string of Ruby code. This big string is the final product that can be written to a file and executed by the Ruby interpreter.

## Transpiling Rux to Ruby

While the `ruxc` tool is a convenient way to transpile rux to Ruby via the command line, it's also possible to do so programmatically.

### Transpiling Strings

Let's say you have a string containing a bunch of rux code. You can transpile it to Ruby like so:

```ruby
require 'rux'

str = 'some rux code'
Rux.to_ruby(str)
```

**NOTE**: The `to_ruby` method accepts a visitor instance as its second argument (see below for more information about creating custom visitors). It uses the default visitor if no second argument is provided.

### Transpiling Files

Rux comes with a handy `File` class to make transpiling files easier:

```ruby
require 'rux'

f = Rux::File.new('path/to/some/file.rux')

# get result as a string, same as calling Rux.to_ruby
f.to_ruby

# write result to path/to/some/file.ruxc
f.write

# write result to the given file
f.write('somewhere/else/file.ruxc')

# the default file the result will be written, i.e. the location
# #write will write to
f.default_outfile
```

### The .ruxc File Extension

By default, `Rux::File` will write to files ending with the .ruxc file extension. While it might at first glance seem to make more sense to write .rb files, I decided to use .ruxc so .rux files can be `require`d in environments like Rails applications. Since `require` assumes the file extension is always .rb, there's no way to distinguish between .rux files and their transpiled counterparts without searching the load path every time _any_ file is `require`d. The .ruxc file extension provides a short-circuit - we only have to search the load path if `require` raises a `LoadError`.

## Custom Visitors

Rux comes with a default visitor capable of emitting Ruby code that is mostly compatible with the view_component gem discussed earlier. A little bit of extra work is required to render rux components in Rails, which is why the rux-rails gem uses a modified version of the default visitor to emit Ruby code that will render correctly in Rails views. It's likely other frameworks that want to render rux components will need a custom visitor as well.

Visitors should inherit from the `Rux::Visitor` class and implement the various methods. See lib/rux/visitor.rb for details. If you're looking to tweak the default visitor, inherit from `Rux::DefaultVisitor` instead, and see lib/rux/default_visitor.rb for details.

## Custom Tag Builders

The `Rux.tag` method emits HTML tags via the configured tag builder. You can configure a custom tag builder by setting `Rux.tag_builder` to any object that responds to the `call` method (and accepts three arguments). For example:

```ruby
class MyTagBuilder
  def call(tag_name, attributes = {}, &block)
    # Should return a string, eg. '<div foo="bar"></div>'.
    # When called, the block should return the tag's body contents.
  end
end

Rux.tag_builder = MyTagBuilder.new
```

Or, since the only requirement is that the tag builder respond to `#call`, you could pass a lambda:

```ruby
Rux.tag_builder = -> (tag_name, attributes = {}, &block) do
  # Should return a string, eg. '<div foo="bar"></div>'.
  # When called, the block should return the tag's body contents.
end
```

## Custom Buffers

You may have noticed calls to `Rux.create_buffer` in the code examples above. Rux comes with a default buffer implementation, but you can configure a custom one as well. The rux-rails gem for example configures rux to use `ActiveSupport::SafeBuffer` in order to be compatible with Rails view rendering. Buffer implementations only need to define two methods: `#>>` and `#to_s`:

```ruby
class MyBuffer
  def initialize
    @buffer = ''
  end

  def <<(thing)
    # it's important to handle nils here
    @buffer << (thing || '')
  end

  def to_s
    @buffer
  end
end

Rux.buffer = MyBuffer
```

## The Library Path

It is my hope that, in the future, Ruby and Rails devs will publish collections of view components in gem form that other devs can use in their own projects. Maybe some of those view component libraries will even be written in rux. Accordingly, I wanted a way of adding rux components to Rails' eager load system, but without actually depending on Rails.

The rux library path is a way for libraries written in rux to register themselves. The rux-rails gem automatically appends every entry in the library path to the Rails eager load and autoload paths so .rux files are automatically reloaded in development mode. Hopefully the library path enables other frameworks to do something similar.

Adding a path is done like so:

```ruby
Rux.library_paths << 'path/to/dir/with/rux/files'
```

## Running Tests

`bundle exec rspec` should do the trick.

## License

Licensed under the MIT license. See LICENSE for details.

## Authors

* Cameron C. Dutro: http://github.com/camertron
