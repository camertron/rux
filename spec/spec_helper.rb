require 'rspec'
require 'rux'

$:.push(File.join(__dir__, 'support'))

require 'view_component/base'

Dir.chdir(File.join(__dir__, 'support')) do
  Dir.glob('components/*.rb').each do |component_file|
    require component_file
  end
end

module Rux
  module ParserTestHelpers
    def compile(rux_code)
      Rux.to_ruby(rux_code)
    end
  end

  module RenderTestHelpers
    def render(rux_code, **kwargs)
      ruby_code = Rux.to_ruby(rux_code)
      ViewComponent::Base.new.instance_exec(ruby_code, **kwargs) do |ruby_code, **kwargs|
        eval(ruby_code)
      end
    end
  end
end

RSpec.configure do |config|
  config.include(Rux::ParserTestHelpers, type: :parser)
  config.include(Rux::RenderTestHelpers, type: :render)
end
