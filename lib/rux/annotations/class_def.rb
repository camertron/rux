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
          result << indent("class #{type.to_ruby}#{super_class}\n", level)
          result << indent("extend T::Sig\n", level + 1)

          if type.has_args?
            type_args = "extend T::Generic\n\n".tap do |body|
              type.args.each do |type_arg|
                body << "#{type_arg.const.to_ruby} = type_member\n"
              end

              body << "\n"
            end

            result << indent(type_args, level + 1)
          else
            result << "\n"
          end

          lines = []

          unless mixins.empty?
            lines << mixins.map do |kind, const|
              indent("#{kind} #{const.to_ruby}", level + 1)
            end.join("\n")
          end

          attr_ivars = ivars.select(&:attr?)
          unless attr_ivars.empty?
            lines << attr_ivars.map do |ivar|
              ivar.attrs.map { |a| a.to_rbi(level + 1) }.join("\n\n")
            end
          end

          lines += methods.flat_map do |mtd|
            if mtd.name == 'initialize' && !ivars.empty?
              mtd.to_rbi(level + 1) do
                ivars.map { |ivar| ivar.to_rbi(level + 2) }.join("\n")
              end
            else
              mtd.to_rbi(level + 1)
            end
          end

          unless scopes.empty?
            lines << scopes.map { |scp| scp.to_rbi(level + 1) }.join("\n")
          end

          result << lines.join("\n\n")
          result << indent("\nend\n", level)
        end
      end
    end
  end
end
