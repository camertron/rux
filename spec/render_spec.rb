require 'spec_helper'

describe Rux do
  def render(rux_code, **kwargs)
    ruby_code = Rux.to_ruby(rux_code)
    # puts ruby_code
    ViewComponent::Base.new.instance_exec(ruby_code, **kwargs) do |ruby_code, **kwargs|
      eval(ruby_code)
    end
  end

  it 'handles a HTML tags inside ruby code' do
    result = render(<<~RUBY)
      <div>
        {3.times.map do
          <p>Welcome!</p>
        end}
      </div>
    RUBY

    expect(result).to eq("<div><p>Welcome!</p><p>Welcome!</p><p>Welcome!</p></div>")
  end

  it 'handles rux tags inside ruby code' do
    result = render(<<~RUBY)
      <div>
        {3.times.map do
          <TestComponent><p>Welcome!</p></TestComponent>
        end}
      </div>
    RUBY

    expect(result).to eq("<div><p>Welcome!</p><p>Welcome!</p><p>Welcome!</p></div>")
  end

  it 'correctly handles keyword arguments (ruby 3)' do
    result = render(<<~RUBY)
      <ArgsComponent a="a" b="b" />
    RUBY

    expect(result).to eq("<p>a and b</p>")
  end

  it 'removes whitespace between elements and text' do
    result = render(<<~RUBY)
      <div>
        <p>Hello World</p>

        <p>
          Hello World
        </p>

        <p>
          Hello
          World
        </p>

        <p>

          Hello World
        </p>
      </div>
    RUBY

    expect(result).to eq(
      "<div><p>Hello World</p><p>Hello World</p><p>Hello World</p><p>Hello World</p></div>"
    )
  end

  it 'slugifies ruby arguments' do
    result = render(<<~RUBY)
      <DataComponent data-foo="foo" />
    RUBY

    expect(result).to eq(
      "<div data-foo=\"foo\"></div>"
    )
  end

  it 'does not slugify HTML attributes' do
    result = render(<<~RUBY)
      <div data-foo="bar"></div>
    RUBY

    expect(result).to eq(
      "<div data-foo=\"bar\"></div>"
    )
  end

  it 'renders slots correctly' do
    result = render(<<~RUBY)
      <TableComponent>
        <WithRow>
          <WithColumn>Foo 1</WithColumn>
        </WithRow>
        <WithRow>
          <WithColumn>Foo 2</WithColumn>
        </WithRow>
      </TableComponent>
    RUBY

    expect(result).to eq(
      "<table><tr><td>Foo 1</td></tr><tr><td>Foo 2</td></tr></table>"
    )
  end

  it 'calls .to_s on anything appended to a buffer' do
    result = render(<<~RUBY)
      <div>
        {[["foo", "bar"], ["baz", "boo"]].map do |row|
          <>{row}</>
        end}
      </div>
    RUBY
    expect(result).to eq(
      '<div>foobarbazboo</div>'
    )
  end

  it 'escapes arbitrary ruby expressions' do
    result = render(<<~RUBY, value: "<p>Foo</p>")
      <div>{kwargs[:value]}</div>
    RUBY
    expect(result).to eq(
      "<div>&lt;p&gt;Foo&lt;/p&gt;</div>"
    )
  end

  it 'escapes double quotes in HTML attributes' do
    result = render(<<~RUBY)
      <div class={'"foo"'}>foo</div>
    RUBY
    expect(result).to eq(
      "<div class=\"&quot;foo&quot;\">foo</div>"
    )
  end
end
