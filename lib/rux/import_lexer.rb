module Rux
  class ImportLexer < StateBasedLexer
    class << self
      def state_table
        @state_table ||= StateTable.new(state_table_path, :START, 'tRUX_IMPORT_')
      end

      private

      # See: https://docs.google.com/spreadsheets/d/11ikKuySIKoaj-kFIfhlzebUwH31cRt_1flGjWfk7RMg/edit#gid=1255509262
      def state_table_path
        @state_table_path ||=
          ::File.expand_path(::File.join('.', 'lex', 'import_states.csv'), __dir__)
      end
    end


    def initialize(source_buffer, init_pos, context)
      @context = context

      super(
        StateMachine.new(
          self.class.state_table, source_buffer, init_pos
        )
      )
    end

    private

    def each_token
      # import {Foo as Bar} from Baz
      from = false
      from_const = false

      until from && from_const
        break if @state_machine.eof?

        token = @state_machine.advance
        state, (text, pos) = token

        case state
          when :tRUX_IMPORT_IDENTIFIER
            case text
              when 'import'
                yield [:tRUX_IMPORT, [text, pos]]
              when 'from'
                yield [:tRUX_IMPORT_FROM, [text, pos]]
                from = true
              when 'as'
                yield [:tRUX_IMPORT_AS, [text, pos]]
              else
                from_const = true if from
                yield [:tRUX_IMPORT_CONST, [text, pos]]
            end
          when :tRUX_IMPORT_COMMA, :tRUX_IMPORT_OPEN_CURLY, :tRUX_IMPORT_CLOSE_CURLY
            yield [state, [text, pos]]
          when :tRUX_IMPORT_SPACES
            break if text.include?("\n")
        end
      end
    end
  end
end
