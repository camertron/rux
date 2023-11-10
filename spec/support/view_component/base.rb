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
