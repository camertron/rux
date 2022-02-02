module Rux
  module Annotations
    autoload :Annotation,        'rux/annotations/annotation'
    autoload :AnnotationVisitor, 'rux/annotations/annotation_visitor'
    autoload :Arg,               'rux/annotations/arg'
    autoload :Args,              'rux/annotations/args'
    autoload :ClassDef,          'rux/annotations/class_def'
    autoload :IVar,              'rux/annotations/ivar'
    autoload :MethodDef,         'rux/annotations/method_def'
    autoload :ModuleDef,         'rux/annotations/module_def'
    autoload :RBSVisitor,        'rux/annotations/rbs_visitor'
    autoload :Scope,             'rux/annotations/scope'
    autoload :TopLevelScope,     'rux/annotations/top_level_scope'
    autoload :TypeList,          'rux/annotations/type_list'
    autoload :UnionType,         'rux/annotations/union_type'

    # types
    autoload :ArrayType,         'rux/annotations/types'
    autoload :ClassOf,           'rux/annotations/types'
    autoload :EnumerableType,    'rux/annotations/types'
    autoload :EnumeratorType,    'rux/annotations/types'
    autoload :HashType,          'rux/annotations/types'
    autoload :NilType,           'rux/annotations/types'
    autoload :ProcType,          'rux/annotations/types'
    autoload :RangeType,         'rux/annotations/types'
    autoload :SetType,           'rux/annotations/types'
    autoload :Type,              'rux/annotations/types'
    autoload :UntypedType,       'rux/annotations/types'

    class << self
      def register_type_class(const, type_klass)
        registered_type_classes[const] = type_klass
      end

      def get_type(const, *args)
        if type_klass = registered_type_classes[const.to_ruby]
          type_klass.new(*args)
        else
          Type.new(const, *args)
        end
      end

      private

      def registered_type_classes
        @registered_type_classes ||= {}
      end
    end


    register_type_class("Array", ArrayType)
    register_type_class("ClassOf", ClassOf)
    register_type_class("Enumerable", EnumerableType)
    register_type_class("Enumerator", EnumeratorType)
    register_type_class("Hash", HashType)
    register_type_class("Proc", ProcType)
    register_type_class("Range", RangeType)
    register_type_class("Set", SetType)
  end
end
