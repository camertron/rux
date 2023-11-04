require 'rspec'
require 'rux'
require 'pry-byebug'

# a very basic implementation of the view_component lib
module ViewComponent
  class Slot
    def initialize(component_instance, content_block)
      @component_instance = component_instance
      @content_block = content_block
    end

    def to_s
      @component_instance.content = @content_block.call(@component_instance) if @content_block
      @component_instance.call
    end
  end

  class Base
    class << self
      def renders_many(name, component)
        singular_name = name.to_s.chomp("s")

        registered_slots[name] = {
          renderable: component,
          collection: true
        }

        define_method(:"with_#{singular_name}") do |*args, **kwargs, &block|
          slots[name] ||= []
          slots[name] << Slot.new(component.new(*args, **kwargs), block)
          nil
        end

        define_method(name) do
          slots[name] || []
        end
      end

      private

      def registered_slots
        @registered_slots ||= {}
      end
    end

    attr_accessor :content

    def render(component, &block)
      if block
        component.content = block.call(component)
      end

      component.call
    end

    private

    def slots
      @slots ||= {}
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

class DataComponent < ViewComponent::Base
  def initialize(data_foo:)
    @data_foo = data_foo
  end

  def call
    "<div data-foo=\"#{@data_foo}\"></div>"
  end
end

class ColumnComponent < ViewComponent::Base
  def call
    "<td>#{content}</td>"
  end
end

class RowComponent < ViewComponent::Base
  renders_many :columns, ColumnComponent

  def call
    "<tr>#{columns.map(&:to_s).join}</tr>"
  end
end

class TableComponent < ViewComponent::Base
  renders_many :rows, RowComponent

  def call
    "<table>#{rows.map(&:to_s).join}</table>"
  end
end

RSpec.configure do |config|
end
