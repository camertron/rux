$:.push(__dir__)

require 'rspec'
require 'rux'
require 'pry-byebug'

Dir.chdir(__dir__) do
  Dir['support/*.rb'].each { |f| require f }
end

module RuxSpecHelpers
  def compile(rux_code, pretty: true)
    Rux.to_ruby(rux_code, pretty: pretty)
  end
end

module RuxSpecMatchers
  def import(*const)
    Rux::ImportMatcher.new(*const)
  end
end

RSpec.configure do |config|
  config.include RuxSpecHelpers
  config.include RuxSpecMatchers
end
