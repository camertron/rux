require 'cgi'

module Rux
  autoload :AST,       'rux/ast'
  autoload :Lex,       'rux/lex'
  autoload :Lexer,     'rux/lexer'
  autoload :Parser,    'rux/parser'
  autoload :RubyLexer, 'rux/ruby_lexer'
  autoload :RuxLexer,  'rux/rux_lexer'
  autoload :Template,  'rux/template'
  autoload :Utils,     'rux/utils'

  class << self
    def tag(tag_name, attributes = {})
      ("<#{tag_name} #{serialize_attrs(attributes)}>" <<
        (block_given? ? Array(yield) : []).join <<
        "</#{tag_name}>"
      ).html_safe
    end

    def serialize_attrs(attributes)
      ''.tap do |result|
        attributes.each_pair.with_index do |(k, v), idx|
          result << ' ' unless idx == 0
          result << "#{k.to_s.gsub('-', '_')}=\"#{CGI.escape_html(v)}\""
        end
      end
    end

    def library_paths
      @library_paths ||= []
    end
  end
end
