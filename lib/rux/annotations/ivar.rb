module Rux
  module Annotations
    class Attr < Annotation
      attr_reader :ivar

      def initialize(ivar)
        @ivar = ivar
      end

      def to_rbi(level)
        indent("#{sig}\n#{kind} #{sym(ivar.bare_name)}", level)
      end

      def to_rbs(level)
        indent("#{ivar.name}: #{ivar.type.sig}", level)
      end

      def private?
        ivar.private?
      end

      def public?
        ivar.public?
      end

      def accept(visitor, level)
        visitor.visit_attr(self, level)
      end
    end

    class AttrReader < Attr
      def kind
        'attr_reader'
      end

      def sig
        "sig { returns(#{ivar.sig}) }"
      end

      def method_sym
        sym(method_str)
      end

      def method_str
        ivar.bare_name
      end
    end

    class AttrWriter < Attr
      def kind
        'attr_writer'
      end

      def sig
        "sig { params(#{sym_join(ivar.bare_name, ivar.sig)}).void }"
      end

      def method_sym
        sym(method_str)
      end

      def method_str
        "#{ivar.bare_name}="
      end
    end

    class IVar < Annotation
      attr_reader :name, :type, :modifiers

      def initialize(name, type, modifiers)
        @name = name
        @type = type
        @modifiers = modifiers
      end

      def bare_name
        @bare_name ||= name[1..-1]
      end

      def symbol
        sym(bare_name)
      end

      def attr?
        !attrs.empty?
      end

      def attrs
        @attrs ||= if modifiers.include?('attr_reader')
          [AttrReader.new(self)]
        elsif modifiers.include?('attr_writer')
          [AttrWriter.new(self)]
        elsif modifiers.include?('attr_accessor')
          [AttrReader.new(self), AttrWriter.new(self)]
        else
          []
        end
      end

      def private?
        modifiers.include?('private')
      end

      def public?
        modifiers.include?('public')
      end

      def accept(visitor, level)
        visitor.visit_ivar(self, level)
      end
    end
  end
end
