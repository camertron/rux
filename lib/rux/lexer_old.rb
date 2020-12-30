require 'csv'
require 'parser'

module Rux
  class Lexer < ::Parser::Lexer
    # These are populated when ::Parser::Lexer loads and are therefore
    # not inherited. We have to copy them over manually.
    ::Parser::Lexer.instance_variables.each do |ivar|
      instance_variable_set(ivar, ::Parser::Lexer.instance_variable_get(ivar))
    end


    class << self
      def state_table
        @state_table ||= {}.tap do |table|
          state_table_data = CSV.read(state_table_path)
          input_patterns = state_table_data[0][1..-1]

          inputs = input_patterns.map do |pattern|
            parse_pattern(pattern)
          end

          state_table_data[1..-1].each do |row|
            next unless row[0]  # allows blank lines in csv

            state = Lex::State.parse(row[0], row[1..-1], inputs)
            table[state.name] = state
          end
        end
      end

      def state_table_path
        @state_table_path ||=
          File.expand_path(File.join('.', 'lex', 'states.csv'), __dir__)
      end

      def parse_pattern(pattern)
        if pattern == "(space)"
          Lex::CharsetPattern.new([' ', "\r", "\n"])
        elsif pattern == "(default)"
          Lex::DefaultPattern.new
        elsif pattern.start_with?('[^')
          Lex::NegatedCharsetPattern.parse(pattern[2..-2])
        else
          Lex::CharsetPattern.parse(pattern[1..-2])
        end
      end
    end


    def source_buffer=(source_buffer)
      super

      @generator = to_enum(:each_token)
      @rux_token_queue = []
    end

    # def reset(reset_state=true)
    #   super

    #   @generator = to_enum(:each_token)
    #   @rux_token_queue.clear if @rux_token_queue
    # end

    alias :advance_orig :advance

    def advance
      @generator.next
    rescue StopIteration
      [nil, ['$eof']]
    end

    private

    def each_token(&block)
      populate_queue

      until @rux_token_queue.empty?
        if at_rux?
          yield @rux_token_queue.shift
          reset_pos(@rux_token_queue[1][1][1].begin_pos - 1)
          @rux_token_queue.clear
          lex_rux(&block)
        end

        populate_queue
        yield @rux_token_queue.shift
        populate_queue
      end
    end

    def populate_queue
      until @rux_token_queue.size >= 3
        cur_token = advance_orig
        break unless cur_token[0]
        @rux_token_queue << cur_token
      end
    end

    def at_rux?
      is_not?(@rux_token_queue[0], :kCLASS) &&
        is?(@rux_token_queue[1], :tLT) &&
        is?(@rux_token_queue[2], :tCONSTANT)
    end

    def lex_rux
      tag_stack = []
      eof = false

      each_rux_token do |token|
        yield token

        state, (text, pos) = token

        case state
          when :tRUX_TAG_OPEN, :tRUX_TAG_SELF_CLOSING
            tag_stack.push(text)
          when :tRUX_TAG_CLOSE
            tag_stack.pop
          when :tRUX_TAG_CLOSE_END
            if tag_stack.empty?
              reset_pos(pos.end_pos)
              @rux_token_queue.clear
              @token_queue.clear
              break
            end
        end
      end
    end

    def make_range(start, stop)
      ::Parser::Source::Range.new(@source_buffer, start, stop)
    end

    def each_rux_token(&block)
      return to_enum(__method__) unless block_given?

      cur_state = :tRUX_START
      last_idx = @p

      loop do
        chr = @source_pts[@p].chr
        cur_trans = self.class.state_table[cur_state][chr]
        cur_state = cur_trans.to_state
        @p += cur_trans.advance_count

        if ruby_code?(cur_state)
          curlies = 1

          until curlies == 0
            each_token do |token|
              type, (_, pos) = token

              case type
                when :tLCURLY, :tLBRACE
                  curlies += 1
                when :tRCURLY, :tRBRACE
                  curlies -= 1
              end

              # i.e. if we're back in rux code
              if self.class.state_table.include?(type)
                reset_pos(pos.begin_pos)
                token_text = @source_buffer.source[last_idx...@p]
                yield [cur_state, [token_text, make_range(last_idx, @p)]]

                lex_rux(&block)

                last_idx = @p
                # @rux_token_queue.clear
                # @token_queue.clear
              end

              if curlies == 0
                reset_pos(pos.begin_pos)
                break
              end
            end
          end
        end

        if self.class.state_table[cur_state].terminal?
          token_text = @source_buffer.source[last_idx...@p]
          yield [cur_state, [token_text, make_range(last_idx, @p)]]

          next_chr = @source_pts[@p].chr

          unless self.class.state_table[cur_state][next_chr]
            cur_state = :tRUX_START
          end

          last_idx = @p
        end
      end
    end

    def reset_pos(pos)
      @ts = @te = @p = pos
    end

    def ruby_code?(state)
      state == :tRUX_ATTRIBUTE_VALUE_RUBY_CODE ||
        state == :tRUX_LITERAL_RUBY_CODE
    end

    def is?(tok, sym)
      tok && tok[0] == sym
    end

    def is_not?(tok, sym)
      tok && tok[0] != sym
    end
  end
end
