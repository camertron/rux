module Rux
  module Annotations
    class ModuleDef < Scope
      def to_rbi(level)
        ''.tap do |result|
          result << indent("module #{type.to_ruby}\n", level)
          result << super(level + 1)
          result << indent("end\n", level)
        end
      end
    end
  end
end
