require 'singleton'

module Rux
  module Annotations
    class Constant < Annotation
      attr_reader :tokens

      def initialize(tokens)
        @tokens = tokens
      end

      def to_ruby
        @ruby ||= tokens.map { |_, (text, _)| text }.join
      end

      def accept(visitor, level)
        visitor.visit_constant(self, level)
      end
    end


    class Type < Annotation
      attr_reader :const, :args

      def initialize(const, *args)
        @const = const
        @args = args
      end

      def to_ruby
        const.to_ruby
      end

      def sig
        const.to_ruby.tap do |result|
          unless args.empty?
            result << "[#{args.map(&:sig).join(', ')}]"
          end
        end
      end

      def has_args?
        !args.empty?
      end

      def accept(visitor, level)
        visitor.visit_type(self, level)
      end
    end


    class NilType < Annotation
      include Singleton

      def accept(visitor, level)
        visitor.visit_nil_type(self, level)
      end
    end


    class UntypedType < Annotation
      include Singleton

      def accept(visitor, level)
        visitor.visit_untyped_type(self, level)
      end
    end


    class ProcType < Annotation
      attr_reader :arg_types, :return_type

      def initialize(arg_types, return_type)
        @arg_types = arg_types
        @return_type = return_type
      end

      def sig
        result = ["T.proc"].tap do |parts|
          unless arg_types.empty?
            at = arg_types.map.with_index do |arg_type, i|
              "arg#{i}: #{arg_type.sig}"
            end

            parts << "params(#{at.join(', ')})"
          end

          if return_type
            parts << "returns(#{return_type.sig})"
          else
            parts << 'void'
          end
        end

        result.join('.')
      end

      def accept(visitor, level)
        visitor.visit_proc_type(self, level)
      end
    end


    class ArrayType < Annotation
      attr_reader :elem_type

      def initialize(elem_type)
        @elem_type = elem_type
      end

      def sig
        "T::Array[#{elem_type.sig}]"
      end

      def accept(visitor, level)
        visitor.visit_array_type(self, level)
      end
    end


    class SetType < Annotation
      attr_reader :elem_type

      def initialize(elem_type)
        @elem_type = elem_type
      end

      def sig
        "T::Set[#{elem_type.sig}]"
      end

      def accept(visitor, level)
        visitor.visit_set_type(self, level)
      end
    end


    class HashType < Annotation
      attr_reader :key_type, :value_type

      def initialize(key_type, value_type)
        @key_type = key_type
        @value_type = value_type
      end

      def sig
        "T::Hash[#{key_type.sig}, #{value_type.sig}]"
      end

      def accept(visitor, level)
        visitor.visit_hash_type(self, level)
      end
    end


    class RangeType < Annotation
      attr_reader :elem_type

      def initialize(elem_type)
        @elem_type = elem_type
      end

      def sig
        "T::Range[#{elem_type.sig}]"
      end

      def accept(visitor, level)
        visitor.visit_range_type(self, level)
      end
    end


    class EnumerableType < Annotation
      attr_reader :elem_type

      def initialize(elem_type)
        @elem_type = elem_type
      end

      def sig
        "T::Enumerable[#{elem_type.sig}]"
      end

      def accept(visitor, level)
        visitor.visit_enumerable_type(self, level)
      end
    end


    class EnumeratorType < Annotation
      attr_reader :elem_type

      def initialize(elem_type)
        @elem_type = elem_type
      end

      def sig
        "T::Enumerator[#{elem_type.sig}]"
      end

      def accept(visitor, level)
        visitor.visit_enumerator_type(self, level)
      end
    end


    class ClassOf < Annotation
      attr_reader :type

      def initialize(type)
        @type = type
      end

      def sig
        "T.class_of(#{type.sig})"
      end

      def accept(visitor, level)
        visitor.visit_class_of(self, level)
      end
    end


    class SelfType
      def sig
        'T.self_type'
      end

      def accept(visitor, level)
        visitor.visit_self_type(self, level)
      end
    end
  end
end
