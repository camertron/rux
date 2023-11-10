require 'spec_helper'

describe 'attributes', type: :parser do
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

  it 'handles unquoted rux attributes' do
    expect(compile('<Hello foo=bar />')).to eq(
      'render(Hello.new(foo: "bar"))'
    )

    expect(compile('<Hello foo=bar></Hello>')).to eq(
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
end
