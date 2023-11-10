require 'view_component/base'

class DataComponent < ViewComponent::Base
  def initialize(data_foo:)
    @data_foo = data_foo
  end

  def call
    "<div data-foo=\"#{@data_foo}\"></div>"
  end
end
