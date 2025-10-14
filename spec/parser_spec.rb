require 'spec_helper'
require 'parser'
require 'unparser'

describe 'parsing', type: :parser do
  it 'raises an error on premature end of input' do
    expect { compile('<Hello') }.to raise_error(Rux::Lexer::EOFError)
  end

  it 'raises an error when no state transition can be found' do
    expect { compile('<Hello <foo>') }.to(
      raise_error(Rux::Lexer::TransitionError,
        'no transition found from tRUX_ATTRIBUTE_SPACES_BODY for "<" at position 7 '\
          'while lexing rux code')
    )
  end

  it 'raises an error on tag mismatch' do
    expect { compile('<Hello></Goodbye>') }.to(
      raise_error(Rux::Parser::TagMismatchError,
        "closing tag 'Goodbye' on line 1 did not match opening tag 'Hello' "\
        'on line 1')
    )
  end

  it 'emits spaces between adjacent ruby code snippets' do
    expect(compile("<Hello>{first} {second}</Hello>")).to eq(<<~RUBY.strip)
      render(Hello.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append(first)
          _rux_buf_.safe_append(" ")
          _rux_buf_.append(second)
        }.to_s
      }
    RUBY
  end

  it 'does not emit spaces for newlines or indentation' do
    code = <<~RUX
      <Hello>
        <Hola>{first} {second}</Hola>
        <Hola>{first} {second}</Hola>
      </Hello>
    RUX
    expect(compile(code)).to eq(<<~RUBY.strip)
      render(Hello.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append(render(Hola.new) { |rux_block_arg1|
            Rux.create_buffer.tap { |_rux_buf_|
              _rux_buf_.append(first)
              _rux_buf_.safe_append(" ")
              _rux_buf_.append(second)
            }.to_s
          })
          _rux_buf_.append(render(Hola.new) { |rux_block_arg1|
            Rux.create_buffer.tap { |_rux_buf_|
              _rux_buf_.append(first)
              _rux_buf_.safe_append(" ")
              _rux_buf_.append(second)
            }.to_s
          })
        }.to_s
      }
    RUBY
  end

  it 'preserves comments' do
    code = <<~RUX
      # frozen_string_literal: true

      class Foo
        def call
          <p>Hello</p>
        end
      end
    RUX
    expect(compile(code)).to eq(<<~RUBY)
      # frozen_string_literal: true
      class Foo
        def call
          Rux.tag("p") {
            Rux.create_buffer.tap { |_rux_buf_|
              _rux_buf_.safe_append("Hello")
            }.to_s
          }
        end
      end
    RUBY
  end
end
