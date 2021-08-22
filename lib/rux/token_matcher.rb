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
        rescue NoMethodError, AnnotationLexer::UnexpectedTokenError
          # Rescue NoMethodErrors because we're asking the ruby lexer (from the
          # Parser gem) to start at an arbitrary position inside the source
          # buffer. It may encounter foreign rux tokens it's not expecting, etc.
          # Best to stop trying to look ahead and call it quits.
          #
          # Rescue UnexpectedTokenErrors from the AnnotationLexer for similar
          # reasons. Imagine a string of Rux code that contains a Ruby keyword
          # in one of its literals, eg: <Hello>abc {foo} def {bar}</Hello>. The
          # "def" is a Ruby keyword but not a valid method definition. The
          # annotation lexer will choke when it tries to consume the method name,
          # which doesn't exist. This normally wouldn't be a problem since the
          # lexer chain should stop lexing Ruby code when it encounters the
          # closing curly, but the naïve lookahead logic here in TokenMatcher
          # doesn't have any way of knowing where to stop. Instead we rescue and
          # stop trying to look ahead in the hopes that another lexer further up
          # the chain knows what to do.
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
