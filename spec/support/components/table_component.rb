require 'view_component/base'

class ColumnComponent < ViewComponent::Base
  def call
    "<td>#{content}</td>"
  end
end

class RowComponent < ViewComponent::Base
  renders_many :columns, ColumnComponent

  def call
    "<tr>#{columns.map(&:to_s).join}</tr>"
  end
end

class TableComponent < ViewComponent::Base
  renders_many :rows, RowComponent

  def call
    "<table>#{rows.map(&:to_s).join}</table>"
  end
end
