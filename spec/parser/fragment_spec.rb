require 'spec_helper'

describe 'fragments', type: :parser do
  it 'allows fragments' do
    code = <<~RUX
      <>
        <div>Foo 1</div>
        <div>Foo 2</div>
      </>
    RUX
    expect(compile(code)).to eq(<<~RUBY.strip)
      Rux.create_buffer.tap { |_rux_buf_|
        _rux_buf_.append(Rux.tag("div") {
          Rux.create_buffer.tap { |_rux_buf_|
            _rux_buf_.safe_append("Foo 1")
          }.to_s
        })
        _rux_buf_.append(Rux.tag("div") {
          Rux.create_buffer.tap { |_rux_buf_|
            _rux_buf_.safe_append("Foo 2")
          }.to_s
        })
      }.to_s
    RUBY
  end

  it 'allows fragments nested inside ruby code' do
    code = <<~RUX
      <table>
        {rows.map do |row|
          <>{row}</>
        end}
      </table>
    RUX
    expect(compile(code)).to eq(<<~RUBY.strip)
      Rux.tag("table") {
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append(rows.map { |row|
            Rux.create_buffer.tap { |_rux_buf_|
              _rux_buf_.append(row)
            }.to_s
          })
        }.to_s
      }
    RUBY
  end

  it 'allows fragments nested inside other tags' do
    code = <<~RUX
      <div>
        <>{"foo"}</>
      </div>
    RUX
    expect(compile(code)).to eq(<<~RUBY.strip)
      Rux.tag("div") {
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append(Rux.create_buffer.tap { |_rux_buf_|
            _rux_buf_.append("foo")
          }.to_s)
        }.to_s
      }
    RUBY
  end
end
