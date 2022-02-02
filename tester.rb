class FooComponent < ViewComponent::Base
  attr_reader(:people)
  private(:people)

  def initialize(people)
    @people = people
  end

  def call
    render(Hello.new) {
      Rux.create_buffer.tap { |_rux_buf_|
        _rux_buf_ << " "
        _rux_buf_ << Rux.tag("div", class: "foo") {
          " Bar! "
        }
        _rux_buf_ << " "
      }.to_s
    }
  end
end
