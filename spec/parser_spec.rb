require 'spec_helper'
require 'parser'
require 'unparser'

describe Rux::Parser do
  def compile(rux_code)
    Unparser.unparse(
      ::Parser::CurrentRuby.parse(
        described_class.parse(rux_code).to_ruby
      )
    )
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
      render(Hello.new) {
        "foo".html_safe
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
      render(Hello.new(foo: [1, 2, 3].map { |n,|
        n * 2
      }))
    RUBY
  end

  it 'handles simple ruby statements in tag bodies' do
    expect(compile('<Hello>{"foo"}</Hello>')).to eq(<<~RUBY.strip)
      render(Hello.new) {
        "foo"
      }
    RUBY
  end

  it 'handles tag bodies containing ruby code with curly braces' do
    expect(compile('<Hello>{[1, 2, 3].map { |n| n * 2 }.join(", ")}</Hello>')).to eq(<<~RUBY.strip)
      render(Hello.new) {
        [1, 2, 3].map { |n,|
          n * 2
        }.join(", ")
      }
    RUBY
  end

  it 'handles tag bodies with intermixed text and ruby code' do
    expect(compile('<Hello>abc {foo} def {bar} baz</Hello>')).to eq(<<~RUBY.strip)
      render(Hello.new) {
        "abc ".html_safe << foo << " def ".html_safe << bar << " baz".html_safe
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
      render(Outer.new) {
        5.times.map {
          render(Inner.new) {
            "What a ".html_safe << @thing
          }
        }
      }
    RUBY
  end

  it 'handles regular HTML tags' do
    expect(compile('<div>foo</div>')).to eq(<<~RUBY.strip)
      Rux.tag("div") {
        "foo".html_safe
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
      render(Outer.new) {
        5.times.map {
          Rux.tag("div") {
            "So ".html_safe << @cool
          }
        }
      }
    RUBY
  end
end
