# a very basic implementation of the view_component lib
module ViewComponent
  class Slot
    def initialize(component_instance, content_block)
      @component_instance = component_instance
      @content_block = content_block
    end

    def to_s
      @component_instance.render_in(nil, &@content_block)
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

    def render(component, &block)
      component.render_in(nil, &block)
    end

    def render_in(_view_context, &block)
      @content_block = block
      content  # fill in slots
      call
    end

    def content
      @content ||= @content_block&.call(self)
    end

    private

    def slots
      @slots ||= {}
    end
  end
end
