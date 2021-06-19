$:.push(__dir__)

require 'rspec'
require 'rux'
require 'pry-byebug'

Dir.chdir(__dir__) do
  Dir['support/*.rb'].each { |f| require f }
end

module RuxSpecHelpers
  def compile(rux_code, pretty: true)
    Rux.to_ruby(rux_code, pretty: pretty)
  end

  def compile_no_imports(rux_code, pretty: true)
    Rux.to_ruby(rux_code, raise_on_missing_imports: false)
  end
end

module RuxSpecMatchers
  def import(*const)
    Rux::ImportMatcher.new(*const)
  end
end

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
  config.include RuxSpecHelpers
  config.include RuxSpecMatchers
end
