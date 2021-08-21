module Rux
  module Imports
    autoload :Import,         'rux/imports/import'
    autoload :ImportInfo,     'rux/imports/import_info'
    autoload :ImportedConst,  'rux/imports/imported_const'
    autoload :ImportList,     'rux/imports/import_list'
    autoload :ImportRewriter, 'rux/imports/import_rewriter'
    autoload :ResolvedConst,  'rux/imports/resolved_const'
    autoload :Scope,          'rux/imports/scope'
    autoload :Sigil,          'rux/imports/sigil'

    class MissingConstantError < StandardError
      attr_reader :missing_const

      def initialize(message, missing_const)
        super(message)
        @missing_const = missing_const
      end
    end
  end
end
