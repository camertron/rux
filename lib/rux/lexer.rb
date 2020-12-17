require 'csv'

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

    def reset(reset_state=true)
      super

      @generator = to_enum(:each_token)
      @rux_token_queue.clear if @rux_token_queue
    end

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
          @ts = @te = @p = @rux_token_queue[1][1][1].begin_pos - 1
          lex_rux(&block)
          @rux_token_queue.clear
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

      each_rux_token do |state, text, start, stop|
        yield [state, [text, make_range(start, stop)]]

        case state
          when :tag_open, :tag_self_closing
            tag_stack.push(text)
          when :tag_close
            tag_stack.pop
          when :tag_close_end
            if tag_stack.empty?
              @ts = @te = @p = stop
              break
            end
        end
      end
    end

    def make_range(start, stop)
      ::Parser::Source::Range.new(@source_buffer, start, stop)
    end

    def each_rux_token
      return to_enum(__method__) unless block_given?

      cur_state = :start
      last_idx = @p

      loop do
        chr = @source_pts[@p].chr
        cur_trans = self.class.state_table[cur_state][chr]
        cur_state = cur_trans.to_state
        @p += cur_trans.advance_count

        if cur_state == :attribute_value_ruby_code || cur_state == :literal_ruby_code
          @te = @ts = @p
          curlies = 1

          until curlies == 0
            token, (_, pos) = advance_orig

            case token
              when :tLCURLY, :tLBRACE
                curlies += 1
              when :tRCURLY, :tRBRACE
                curlies -= 1
            end

            if curlies == 0
              @p = pos.end_pos - 1
            end
          end
        end

        if self.class.state_table[cur_state].terminal?
          token_text = @source_buffer.source[last_idx...@p]
          yield cur_state, token_text, last_idx, @p

          next_chr = @source_pts[@p].chr

          unless self.class.state_table[cur_state][next_chr]
            cur_state = :start
          end

          last_idx = @p
        end
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
