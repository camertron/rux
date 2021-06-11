require 'rspec'
require 'rux'
require 'pry-byebug'

# a very basic implementation of the view_component lib
module ViewComponent
  class Base
    attr_accessor :content

    def render(component, &block)
      component.content = block.call
      component.call
    end
  end
end

class TestComponent < ViewComponent::Base
  def call
    content
  end
end

RSpec.configure do |config|
end
