require 'view_component/base'

class ArgsComponent < ViewComponent::Base
  attr_reader :a, :b

  def initialize(a:, b:)
    @a = a
    @b = b
  end

  def call
    "<p>#{a} and #{b}</p>"
  end
end
