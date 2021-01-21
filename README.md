## rux [![Build Status](https://secure.travis-ci.org/camertron/rux.png?branch=master)](http://travis-ci.org/camertron/rux)

Rux is a JSX-inspired way to write HTML tags in your Ruby code. While it can be used to write view components in Rails via the [rux-rails gem](https://github.com/camertron/rux-rails), this repo contains only the rux parser itself.

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

Rux does one thing: it lets you write HTML in your Ruby code. Here's the name component example from earlier rewritten in rux (sorry about the syntax highlighting, Github doesn't know about rux... yet).

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
    # people is an array of hashes containing :first_name and :last_name
    # keys
    @people = people
  end

  def call
    <div>
      {@people.each do |person|
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

## How it Works

Rux is half its own lexer/parser and half a wrapper around the [Parser gem](https://github.com/whitequark/parser).

## Running Tests

`bundle exec rspec` should do the trick.

## License

Licensed under the MIT license. See LICENSE for details.

## Authors

* Cameron C. Dutro: http://github.com/camertron
