require 'spec_helper'

describe Rux do
  def render(rux_code)
    ruby_code, _context = Rux.to_ruby(rux_code)
    ViewComponent::Base.new.instance_eval(ruby_code)
  end

  it 'handles a HTML tags inside ruby code' do
    result = render(<<~RUBY)
      <div>
        {3.times.map do
          <p>Welcome!</p>
        end}
      </div>
    RUBY

    expect(result).to eq("<div> <p>Welcome!</p><p>Welcome!</p><p>Welcome!</p> </div>")
  end

  it 'handles rux tags inside ruby code' do
    result = render(<<~RUBY)
      <div>
        {3.times.map do
          <TestComponent><p>Welcome!</p></TestComponent>
        end}
      </div>
    RUBY

    expect(result).to eq("<div> <p>Welcome!</p><p>Welcome!</p><p>Welcome!</p> </div>")
  end

  it 'correctly handles keyword arguments (ruby 3)' do
    result = render(<<~RUBY)
      <ArgsComponent a="a" b="b" />
    RUBY

    expect(result).to eq("<p>a and b</p>")
  end
end