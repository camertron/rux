require 'view_component/base'

class TestComponent < ViewComponent::Base
  def call
    content
  end
end
