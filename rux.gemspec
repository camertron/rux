$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'rux/version'

Gem::Specification.new do |s|
  s.name     = 'rux'
  s.version  = ::Rux::VERSION
  s.authors  = ['Cameron Dutro']
  s.email    = ['camertron@gmail.com']
  s.homepage = 'http://github.com/camertron/rux'
  s.description = s.summary = 'A jsx-inspired way to write view components.'
  s.platform = Gem::Platform::RUBY

  s.add_dependency 'onload', '~> 1.1'
  s.add_dependency 'parser', '~> 3.0'
  s.add_dependency 'unparser', '~> 0.6'

  s.require_path = 'lib'
  s.executables << 'ruxc'
  s.executables << 'ruxlex'

  s.files = Dir['{lib,spec}/**/*', 'Gemfile', 'LICENSE', 'CHANGELOG.md', 'README.md', 'Rakefile', 'rux.gemspec']
end
