module Rux
  module Annotations
    class ClassDef < Scope
      attr_reader :type, :super_type

      def initialize(type, super_type)
        super(type)
        @super_type = super_type
      end

      def to_rbi(level)
        ''.tap do |result|
          super_class = super_type ? " < #{super_type.to_ruby}" : ''
          result << indent("class #{name}#{super_class}\n", level)
          result << indent("extend T::Sig\n\n", level + 1)

          if type.has_args?
            type_args = "extend T::Generic\n\n".tap do |body|
              type.args.each do |type_arg|
                body << "#{type_arg.const} = type_member\n"
              end

              body << "\n"
            end

            result << indent(type_args, level + 1)
          end

          result << super(level + 1)
          result << indent("end\n", level)
        end
      end
    end
  end
end
