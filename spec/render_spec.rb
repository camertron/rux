require 'spec_helper'

describe Rux do
  def render(rux_code)
    ruby_code = Rux.to_ruby(rux_code)
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
end