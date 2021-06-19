require 'spec_helper'

describe Rux::Parser do
  it 'handles a single self-closing tag' do
    expect(compile_no_imports("<Hello/>")).to eq("render(Hello.new)")
  end

  it 'handles a self-closing tag with spaces preceding the closing punctuation' do
    expect(compile_no_imports("<Hello />")).to eq("render(Hello.new)")
  end

  it 'handles a single opening and closing tag' do
    expect(compile_no_imports("<Hello></Hello>")).to eq('render(Hello.new)')
  end

  it 'handles a single tag with a text body' do
    expect(compile_no_imports("<Hello>foo</Hello>")).to eq(<<~RUBY.strip)
      render(Hello.new) {
        "foo"
      }
    RUBY
  end

  it 'handles single-quoted rux attributes' do
    expect(compile_no_imports("<Hello foo='bar' />")).to eq(
      'render(Hello.new({ foo: "bar" }))'
    )

    expect(compile_no_imports("<Hello foo='bar'></Hello>")).to eq(
      'render(Hello.new({ foo: "bar" }))'
    )
  end

  it 'handles double-quoted rux attributes' do
    expect(compile_no_imports('<Hello foo="bar" />')).to eq(
      'render(Hello.new({ foo: "bar" }))'
    )

    expect(compile_no_imports('<Hello foo="bar"></Hello>')).to eq(
      'render(Hello.new({ foo: "bar" }))'
    )
  end

  it 'handles non-uniform spacing between attributes' do
    expect(compile_no_imports('<Hello  foo="bar"    baz= "boo" bix  ="bit" />')).to eq(
      'render(Hello.new({ foo: "bar", baz: "boo", bix: "bit" }))'
    )
  end

  it 'handles boolean attributes' do
    expect(compile_no_imports('<Hello disabled />')).to eq(
      'render(Hello.new({ disabled: "true" }))'
    )

    expect(compile_no_imports('<Hello disabled/>')).to eq(
      'render(Hello.new({ disabled: "true" }))'
    )

    expect(compile_no_imports('<Hello disabled></Hello>')).to eq(
      'render(Hello.new({ disabled: "true" }))'
    )
  end

  it 'converts dashes to underscores in attribute keys' do
    expect(compile_no_imports('<Hello foo-bar="baz" />')).to eq(
      'render(Hello.new({ foo_bar: "baz" }))'
    )
  end

  it 'handles simple ruby statements in attributes' do
    expect(compile_no_imports('<Hello foo={true} />')).to eq(
      'render(Hello.new({ foo: true }))'
    )
  end

  it 'handles ruby hashes in attributes' do
    expect(compile_no_imports('<Hello foo={{ foo: "bar", baz: "boo" }} />')).to eq(
      'render(Hello.new({ foo: { foo: "bar", baz: "boo" } }))'
    )
  end

  it 'handles ruby code with curly braces in attributes' do
    expect(compile_no_imports('<Hello foo={[1, 2, 3].map { |n| n * 2 }} />')).to eq(<<~RUBY.strip)
      render(Hello.new({ foo: [1, 2, 3].map { |n,|
        n * 2
      }))
    RUBY
  end

  it 'handles simple ruby statements in tag bodies' do
    expect(compile_no_imports('<Hello>{"foo"}</Hello>')).to eq(<<~RUBY.strip)
      render(Hello.new) {
        "foo"
      }
    RUBY
  end

  it 'handles tag bodies containing ruby code with curly braces' do
    expect(compile_no_imports('<Hello>{[1, 2, 3].map { |n| n * 2 }.join(", ")}</Hello>')).to eq(<<~RUBY.strip)
      render(Hello.new) {
        [1, 2, 3].map { |n|
          n * 2
        }.join(", ")
      }
    RUBY
  end

  it 'handles tag bodies with intermixed text and ruby code' do
    expect(compile_no_imports('<Hello>abc {foo} def {bar} baz</Hello>')).to eq(<<~RUBY.strip)
      render(Hello.new) {
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_ << "abc "
          _rux_buf_ << foo
          _rux_buf_ << " def "
          _rux_buf_ << bar
          _rux_buf_ << " baz"
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

    expect(compile_no_imports(rux_code)).to eq(<<~RUBY.strip)
      render(Outer.new) {
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_ << " "
          _rux_buf_ << 5.times.map {
            render(Inner.new) {
              Rux.create_buffer.tap { |_rux_buf_|
                _rux_buf_ << "What a "
                _rux_buf_ << @thing
              }.to_s
            }
          }
          _rux_buf_ << " "
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
          _rux_buf_ << " "
          _rux_buf_ << 5.times.map {
            Rux.tag("p") {
              Rux.create_buffer.tap { |_rux_buf_|
                _rux_buf_ << "What a "
                _rux_buf_ << @thing
              }.to_s
            }
          }
          _rux_buf_ << " "
        }.to_s
      }
    RUBY
  end

  it 'handles regular HTML tags' do
    expect(compile_no_imports('<div>foo</div>')).to eq(<<~RUBY.strip)
      Rux.tag("div") {
        "foo"
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

    expect(compile_no_imports(rux_code)).to eq(<<~RUBY.strip)
      render(Outer.new) {
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_ << " "
          _rux_buf_ << 5.times.map {
            Rux.tag("div") {
              Rux.create_buffer.tap { |_rux_buf_|
                _rux_buf_ << "So "
                _rux_buf_ << @cool
              }.to_s
            }
          }
          _rux_buf_ << " "
        }.to_s
      }
    RUBY
  end

  it 'escapes HTML entities in strings' do
    expect(compile_no_imports('<Hello>"foo"</Hello>')).to eq(<<~RUBY.strip)
      render(Hello.new) {
        "&quot;foo&quot;"
      }
    RUBY
  end

  it 'raises an error on premature end of input' do
    expect { compile_no_imports('<Hello') }.to raise_error(Rux::Lexer::EOFError)
  end

  it 'raises an error when no state transition can be found' do
    expect { compile_no_imports('<Hello <foo>') }.to(
      raise_error(Rux::Lexer::TransitionError,
        'no transition found from tRUX_ATTRIBUTE_SPACES_BODY at position 7 '\
          'while lexing rux code')
    )
  end

  it 'raises an error on tag mismatch' do
    expect { compile_no_imports('<Hello></Goodbye>') }.to(
      raise_error(Rux::Parser::TagMismatchError,
        "closing tag 'Goodbye' on line 1 did not match opening tag 'Hello' "\
        'on line 1')
    )
  end

  it 'emits spaces between adjacent ruby code snippets' do
    expect(compile_no_imports("<Hello>{first} {second}</Hello>")).to eq(<<~RUBY.strip)
      render(Hello.new) {
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_ << first
          _rux_buf_ << " "
          _rux_buf_ << second
        }.to_s
      }
    RUBY
  end
end
