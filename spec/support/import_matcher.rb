module Rux
  class ImportMatcher
    include RSpec::Matchers::Composable

    attr_reader :const, :as_const, :from_const

    def initialize(*const)
      @const = const
    end

    def as(*as_const)
      @as_const = as_const
      self
    end

    def from(*from_const)
      @from_const = from_const
      self
    end

    def matches?(rux_code)
      buffer = ::Parser::Source::Buffer.new('(source)', source: rux_code)
      _rux_ast, context = Rux::RuxParser.parse(buffer)
      resolved_const = context[:imports].resolve(as_const || const)
      return false unless resolved_const

      matches = resolved_const.imported_const.const == const

      if as_const
        matches &&= resolved_const.as_const == as_const
      end

      if from_const
        matches &&= resolved_const.from_const == from_const
      end

      matches
    end

    def failure_message
      "#{const.join('::')} was not imported"
    end
  end
end
