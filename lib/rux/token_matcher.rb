module Rux
  # This could someday form the basis for a custom (or at least, extensible)
  # matcher system which identifies code boundaries
  class TokenMatcher
    LOOKAHEAD = 3

    attr_reader :lexer

    def initialize(lexer)
      @lexer = lexer
      @queue = []
      populate_queue
    end

    def current
      @queue[0]
    end

    def dequeue
      @queue.shift.tap { populate_queue }
    end

    def clear
      @queue.clear
      populate_queue
    end

    def empty?
      @queue.empty?
    end

    def pos
      current[1][1]
    end

    def at_rux?
      at_lt? && !at_inheritance?
    end

    def at_import?
      is?(@queue[0], :tIDENTIFIER) &&
        @queue[0][1][0] == 'import' && (
          is?(@queue[1], :tLCURLY) ||
            is?(@queue[1], :tCONSTANT)
        )
    end

    def at_inheritance?
      is?(@queue[0], :tCONSTANT) &&
        is?(@queue[1], :tLT) &&
        is?(@queue[2], :tCONSTANT)
    end

    def at_lt?
      is?(@queue[0], :tLT) && (
        is?(@queue[1], :tCONSTANT) ||
        is?(@queue[1], :tIDENTIFIER)
      )
    end

    private

    def populate_queue
      until @queue.size >= LOOKAHEAD
        begin
          cur_token = @lexer.advance
        rescue NoMethodError
          # Internal lexer errors can happen since we're asking the ruby lexer
          # to start at an arbitrary position inside the source buffer. It may
          # encounter foreign rux tokens it's not expecting, etc. Best to stop
          # trying to look ahead and call it quits.
          break
        end

        break unless cur_token[0]
        @queue << cur_token
      end
    end

    def is?(tok, sym)
      tok && tok[0] == sym
    end

    def is_not?(tok, sym)
      tok && tok[0] != sym
    end
  end
end
