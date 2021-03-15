module Rux
  module Annotations
    class MethodDef < Scope
      attr_reader :name, :args, :return_type

      def initialize(name, args, return_type)
        @args = args
        @return_type = return_type
        super(name)
      end

      def to_rbi(level)
        indent(<<~END, level)
          #{sig}
          def #{name}(#{args.to_ruby})
          end
        END
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
