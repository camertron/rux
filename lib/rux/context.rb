# frozen_string_literal: true

require "use_context"
require "securerandom"

module Rux
  class ContextBase
    include UseContext::ContextMethods

    class << self
      attr_accessor :default_value, :default_value_block

      def context_key
        @context_key ||= "#{context_name}_context"
      end

      def context_name
        @context_name ||= self.name || SecureRandom.hex
      end
    end

    attr_reader :value

    def initialize(**kwargs)
      if kwargs.include?(:value)
        @value = kwargs[:value]
      else
        @value = if self.class.default_value_block
          self.class.default_value_block.call
        else
          self.class.default_value
        end
      end
    end

    def render_in(_view_context, &block)
      provide_context(self.class.context_key, { value: value }) do
        block.call if block
      end
    end
  end

  module Context
    class << self
      include UseContext::ContextMethods

      def create(default_value = nil, &default_value_block)
        Class.new(ContextBase).tap do |klass|
          klass.default_value = default_value
          klass.default_value_block = default_value_block
        end
      end

      def use(context_class)
        use_context(context_class.context_key, :value)
      end
    end
  end
end
