require 'rspec'
require 'rux'
require 'pry-byebug'

# a very basic implementation of the view_component lib
module ViewComponent
  class Base
    attr_accessor :content

    def render(component, &block)
      component.content = block.call if block
      component.call
    end
  end
end

class TestComponent < ViewComponent::Base
  def call
    content
  end
end

class ArgsComponent < ViewComponent::Base
  attr_reader :a, :b

  def initialize(a:, b:)
    @a = a
    @b = b
  end

  def call
    "<p>#{a} and #{b}</p>"
  end
end

RSpec.configure do |config|
end
