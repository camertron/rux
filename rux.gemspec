$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'rux/version'

Gem::Specification.new do |s|
  s.name     = 'rux'
  s.version  = ::Rux::VERSION
  s.authors  = ['Cameron Dutro']
  s.email    = ['camertron@gmail.com']
  s.homepage = 'http://github.com/camertron/rux'
  s.description = s.summary = 'A React-inspired way to write view components.'
  s.platform = Gem::Platform::RUBY

  s.add_dependency 'parser', '~> 2.7'
  s.add_dependency 'unparser', '~> 0.5'

  # Zeitwerk was introduced in rails 6. I think we should support back to 5.0
  # as well, but for now let's just deal with 6 to limit scope.
  s.add_dependency 'railties', '~> 6.0'

  s.require_path = 'lib'

  s.files = Dir['{lib,spec}/**/*', 'Gemfile', 'LICENSE', 'CHANGELOG.md', 'README.md', 'Rakefile', 'rux.gemspec']
end
