class TestComponent # < ViewComponent::Base
  def initialize(title:, :thing)
    @title = title
    @thing = thing
  end

  def render
    <MyAwesomeForm className="form" title={@title}>
      <div className="form-section">
        <Button>Submit {@thing}</Button>
      </div>
    </MyAwesomeForm>
  end
end
