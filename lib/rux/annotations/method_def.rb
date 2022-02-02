module Rux
  module Annotations
    class MethodDef < Annotation
      attr_reader :name, :args, :return_type

      def initialize(name, args, return_type)
        @name = name
        @args = args
        @return_type = return_type
      end

      def to_rbi(level)
        ''.tap do |result|
          result << indent("#{sig}\n", level)
          result << indent("def #{name}(#{args.to_ruby})\n", level)
          result << "#{yield}\n" if block_given?
          result << indent("end", level)
        end
      end

      def accept(visitor, level)
        visitor.visit_method_def(self, level)
      end

      def top_level_scope?
        false
      end

      private

      def sig
        sig_parts = [].tap do |parts|
          unless args.empty?
            parts << "params(#{args.sig})"
          end

          if return_type
            parts << "returns(#{return_type.sig})"
          else
            parts << "void"
          end
        end

        "sig { #{sig_parts.join('.')} }"
      end
    end
  end
end
