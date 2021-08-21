module Rux
  class StateBasedLexer
    def initialize(state_machine)
      @state_machine = state_machine
      @generator = to_enum(:each_token)
    end

    def advance
      @generator.next
    end

    def reset_to(pos)
      @state_machine.reset_to(pos)
    end

    private

    def each_token
      raise NotImplementedError,
        "`#{__name__}' must be defined in derived classes"
    end
  end
end
