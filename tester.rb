require 'rux'
require 'parser/current'
require 'pry-byebug'


str = File.read('test.rux')
buffer = ::Parser::Source::Buffer.new('(source)', source: str)
lexer = ::Rux::Lexer.new(buffer)

while true
  token, (text, _) = lexer.advance
  puts "#{token}: #{text.inspect}"
  break unless token
end



# source = File.read('tester.rux')

# lexer = ::Rux::Lexer.new(27)
# buffer = ::Parser::Source::Buffer.new('(source)', source: source)
# lexer.source_buffer = buffer
# parser = ::Rux::Parser.new(lexer)
# result = parser.parse
# puts result.map(&:to_ruby).join("\n")

# parser = ::Parser::CurrentRuby.new
# lexer.diagnostics = parser.diagnostics
# lexer.static_env  = parser.static_env
# lexer.context     = parser.context
# parser.instance_variable_set(:@lexer, lexer)

# result = parser.parse(buffer)
# puts result.inspect

# require 'benchmark/ips'

# Benchmark.ips do |x|
#   x.report do
#     buffer = ::Parser::Source::Buffer.new('(source)', source: source)
#     lexer = Rux::Lexer.new(27)
#     lexer.source_buffer = buffer

#     while true
#       tok, (str, _) = lexer.advance
#       # puts "#{tok}: #{str}"
#       break unless tok
#     end
#   end
# end
