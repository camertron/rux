module Rux
  autoload :AST,    'rux/ast'
  autoload :Lex,    'rux/lex'
  autoload :Lexer,  'rux/lexer'
  autoload :Parser, 'rux/parser'
end

# alias :rux_orig_require :require

# def require(file)
#   path = nil

#   $LOAD_PATH.each do |lp|
#     check_path = File.expand_path(File.join(lp, file))

#     if File.exist?(check_path)
#       path = check_path
#       break
#     end
#   end

#   return rux_orig_require(file) unless path
#   return rux_orig_require(file) unless File.extname(path) == '.rux'
#   return false if $LOADED_FEATURES.include?(path)
# rescue Exception
#   return rux_orig_require(file)
# end
