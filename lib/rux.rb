module Rux
  autoload :AST,      'rux/ast'
  autoload :Lex,      'rux/lex'
  autoload :Lexer,    'rux/lexer'
  autoload :Parser,   'rux/parser'
  autoload :Template, 'rux/template'
end

alias :rux_orig_require :require

def require(file)
  begin
    rux_orig_require(file)
  rescue LoadError => e
    path = nil
    rux_file = "#{file}.rux"

    $LOAD_PATH.each do |lp|
      check_path = File.expand_path(File.join(lp, rux_file))

      if File.exist?(check_path)
        path = check_path
        break
      end
    end

    raise unless path
    return false if $LOADED_FEATURES.include?(path)

    ruxc_file = "#{path.chomp('.rux')}.ruxc"
    tmpl = Rux::Template.new(path)
    File.write(ruxc_file, tmpl.to_ruby)
    rux_orig_require(ruxc_file)

    $LOADED_FEATURES << path
    return true
  end
rescue Exception
  return rux_orig_require(file)
end
