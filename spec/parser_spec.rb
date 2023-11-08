require 'spec_helper'
require 'parser'
require 'unparser'

describe Rux::Parser do
  def compile(rux_code)
    Rux.to_ruby(rux_code)
  end

  it 'handles a single self-closing tag' do
    expect(compile("<Hello/>")).to eq("render(Hello.new)")
  end

  it 'handles a self-closing tag with spaces preceding the closing punctuation' do
    expect(compile("<Hello />")).to eq("render(Hello.new)")
  end

  it 'handles a single opening and closing tag' do
    expect(compile("<Hello></Hello>")).to eq('render(Hello.new)')
  end

  it 'handles a single tag with a text body' do
    expect(compile("<Hello>foo</Hello>")).to eq(<<~RUBY.strip)
      render(Hello.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.safe_append("foo")
        }.to_s
      }
    RUBY
  end

  it 'handles single-quoted rux attributes' do
    expect(compile("<Hello foo='bar' />")).to eq(
      'render(Hello.new(foo: "bar"))'
    )

    expect(compile("<Hello foo='bar'></Hello>")).to eq(
      'render(Hello.new(foo: "bar"))'
    )
  end

  it 'handles double-quoted rux attributes' do
    expect(compile('<Hello foo="bar" />')).to eq(
      'render(Hello.new(foo: "bar"))'
    )

    expect(compile('<Hello foo="bar"></Hello>')).to eq(
      'render(Hello.new(foo: "bar"))'
    )
  end

  it 'handles non-uniform spacing between attributes' do
    expect(compile('<Hello  foo="bar"    baz= "boo" bix  ="bit" />')).to eq(
      'render(Hello.new(foo: "bar", baz: "boo", bix: "bit"))'
    )
  end

  it 'handles boolean attributes' do
    expect(compile('<Hello disabled />')).to eq(
      'render(Hello.new(disabled: "true"))'
    )

    expect(compile('<Hello disabled/>')).to eq(
      'render(Hello.new(disabled: "true"))'
    )

    expect(compile('<Hello disabled></Hello>')).to eq(
      'render(Hello.new(disabled: "true"))'
    )
  end

  it 'converts dashes to underscores in attribute keys' do
    expect(compile('<Hello foo-bar="baz" />')).to eq(
      'render(Hello.new(foo_bar: "baz"))'
    )
  end

  it 'handles simple ruby statements in attributes' do
    expect(compile('<Hello foo={true} />')).to eq(
      'render(Hello.new(foo: true))'
    )
  end

  it 'handles ruby hashes in attributes' do
    expect(compile('<Hello foo={{ foo: "bar", baz: "boo" }} />')).to eq(
      'render(Hello.new(foo: { foo: "bar", baz: "boo" }))'
    )
  end

  it 'handles ruby code with curly braces in attributes' do
    expect(compile('<Hello foo={[1, 2, 3].map { |n| n * 2 }} />')).to eq(<<~RUBY.strip)
      render(Hello.new(foo: [1, 2, 3].map { |n|
        n * 2
      }))
    RUBY
  end

  it 'handles simple ruby statements in tag bodies' do
    expect(compile('<Hello>{"foo"}</Hello>')).to eq(<<~RUBY.strip)
      render(Hello.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append("foo")
        }.to_s
      }
    RUBY
  end

  it 'handles tag bodies containing ruby code with curly braces' do
    expect(compile('<Hello>{[1, 2, 3].map { |n| n * 2 }.join(", ")}</Hello>')).to eq(<<~RUBY.strip)
      render(Hello.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append([1, 2, 3].map { |n|
            n * 2
          }.join(", "))
        }.to_s
      }
    RUBY
  end

  it 'handles tag bodies with intermixed text and ruby code' do
    expect(compile('<Hello>abc {foo} def {bar} baz</Hello>')).to eq(<<~RUBY.strip)
      render(Hello.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.safe_append("abc ")
          _rux_buf_.append(foo)
          _rux_buf_.safe_append(" def ")
          _rux_buf_.append(bar)
          _rux_buf_.safe_append(" baz")
        }.to_s
      }
    RUBY
  end

  it 'handles rux tags inside ruby code' do
    rux_code = <<~RUX
      <Outer>
        {5.times.map do
          <Inner>What a {@thing}</Inner>
        end}
      </Outer>
    RUX

    expect(compile(rux_code)).to eq(<<~RUBY.strip)
      render(Outer.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append(5.times.map {
            render(Inner.new) { |rux_block_arg1|
              Rux.create_buffer.tap { |_rux_buf_|
                _rux_buf_.safe_append("What a ")
                _rux_buf_.append(@thing)
              }.to_s
            }
          })
        }.to_s
      }
    RUBY
  end

  it 'handles HTML tags inside ruby code' do
    rux_code = <<~RUX
      <div>
        {5.times.map do
          <p>What a {@thing}</p>
        end}
      </div>
    RUX

    expect(compile(rux_code)).to eq(<<~RUBY.strip)
      Rux.tag("div") {
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append(5.times.map {
            Rux.tag("p") {
              Rux.create_buffer.tap { |_rux_buf_|
                _rux_buf_.safe_append("What a ")
                _rux_buf_.append(@thing)
              }.to_s
            }
          })
        }.to_s
      }
    RUBY
  end

  it 'handles regular HTML tags' do
    expect(compile('<div>foo</div>')).to eq(<<~RUBY.strip)
      Rux.tag("div") {
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.safe_append("foo")
        }.to_s
      }
    RUBY
  end

  it 'handles regular HTML tags inside ruby code' do
    rux_code = <<~RUX
      <Outer>
        {5.times.map do
          <div>So {@cool}</div>
        end}
      </Outer>
    RUX

    expect(compile(rux_code)).to eq(<<~RUBY.strip)
      render(Outer.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append(5.times.map {
            Rux.tag("div") {
              Rux.create_buffer.tap { |_rux_buf_|
                _rux_buf_.safe_append("So ")
                _rux_buf_.append(@cool)
              }.to_s
            }
          })
        }.to_s
      }
    RUBY
  end

  it 'escapes HTML entities in strings' do
    expect(compile('<Hello>"foo"</Hello>')).to eq(<<~RUBY.strip)
      render(Hello.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.safe_append("&quot;foo&quot;")
        }.to_s
      }
    RUBY
  end

  it 'raises an error on premature end of input' do
    expect { compile('<Hello') }.to raise_error(Rux::Lexer::EOFError)
  end

  it 'raises an error when no state transition can be found' do
    expect { compile('<Hello <foo>') }.to(
      raise_error(Rux::Lexer::TransitionError,
        'no transition found from tRUX_ATTRIBUTE_SPACES_BODY at position 7 '\
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

  it 'emits handles spaces between adjacent ruby code snippets' do
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

  it 'slugifies ruby arguments' do
    code = <<~RUX
      <Hello data-foo="bar" />
    RUX
    expect(compile(code)).to eq(<<~RUBY.strip)
      render(Hello.new(data_foo: "bar"))
    RUBY
  end

  it 'does not slugify HTML attributes' do
    code = <<~RUX
      <div data-foo="bar" />
    RUX
    expect(compile(code)).to eq(<<~RUBY.strip)
      Rux.tag("div", { :"data-foo" => "bar" })
    RUBY
  end

  it 'correctly transforms slot components into slot methods' do
    code = <<~RUX
      <TableComponent>
        <WithRow>
          <WithColumn>Foo 1</WithColumn>
        </WithRow>
        <WithRow>
          <WithColumn>Foo 2</WithColumn>
        </WithRow>
      </TableComponent>
    RUX
    expect(compile(code)).to eq(<<~RUBY.strip)
      render(TableComponent.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append((rux_block_arg0.with_row { |rux_block_arg1|
            Rux.create_buffer.tap { |_rux_buf_|
              _rux_buf_.append((rux_block_arg1.with_column { |rux_block_arg2|
                Rux.create_buffer.tap { |_rux_buf_|
                  _rux_buf_.safe_append("Foo 1")
                }.to_s
              }; nil))
            }.to_s
          }; nil))
          _rux_buf_.append((rux_block_arg0.with_row { |rux_block_arg1|
            Rux.create_buffer.tap { |_rux_buf_|
              _rux_buf_.append((rux_block_arg1.with_column { |rux_block_arg2|
                Rux.create_buffer.tap { |_rux_buf_|
                  _rux_buf_.safe_append("Foo 2")
                }.to_s
              }; nil))
            }.to_s
          }; nil))
        }.to_s
      }
    RUBY
  end

  it 'allows fragments' do
    code = <<~RUX
      <>
        <div>Foo 1</div>
        <div>Foo 2</div>
      </>
    RUX
    expect(compile(code)).to eq(<<~RUBY.strip)
      Rux.create_buffer.tap { |_rux_buf_|
        _rux_buf_.append(Rux.tag("div") {
          Rux.create_buffer.tap { |_rux_buf_|
            _rux_buf_.safe_append("Foo 1")
          }.to_s
        })
        _rux_buf_.append(Rux.tag("div") {
          Rux.create_buffer.tap { |_rux_buf_|
            _rux_buf_.safe_append("Foo 2")
          }.to_s
        })
      }.to_s
    RUBY
  end

  it 'allows fragments nested inside ruby code' do
    code = <<~RUX
      <table>
        {rows.map do |row|
          <>{row}</>
        end}
      </table>
    RUX
    expect(compile(code)).to eq(<<~RUBY.strip)
      Rux.tag("table") {
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append(rows.map { |row|
            Rux.create_buffer.tap { |_rux_buf_|
              _rux_buf_.append(row)
            }.to_s
          })
        }.to_s
      }
    RUBY
  end
end
