require 'spec_helper'

describe 'tags', type: :parser do
  it 'handles a single self-closing tag' do
    expect(compile("<Hello/>")).to eq("render(Hello.new)")
  end

  it 'handles a self-closing tag with spaces preceding the closing punctuation' do
    expect(compile("<Hello />")).to eq("render(Hello.new)")
  end

  it 'handles a single opening and closing tag' do
    expect(compile("<Hello></Hello>")).to eq('render(Hello.new)')
  end

  it 'handles a single tag with a text body' do
    expect(compile("<Hello>foo</Hello>")).to eq(<<~RUBY.strip)
      render(Hello.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.safe_append("foo")
        }.to_s
      }
    RUBY
  end

  it 'handles simple ruby statements in tag bodies' do
    expect(compile('<Hello>{"foo"}</Hello>')).to eq(<<~RUBY.strip)
      render(Hello.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append("foo")
        }.to_s
      }
    RUBY
  end

  it 'handles tag bodies containing ruby code with curly braces' do
    expect(compile('<Hello>{[1, 2, 3].map { |n| n * 2 }.join(", ")}</Hello>')).to eq(<<~RUBY.strip)
      render(Hello.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append([1, 2, 3].map { |n|
            n * 2
          }.join(", "))
        }.to_s
      }
    RUBY
  end

  it 'handles tag bodies with intermixed text and ruby code' do
    expect(compile('<Hello>abc {foo} def {bar} baz</Hello>')).to eq(<<~RUBY.strip)
      render(Hello.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.safe_append("abc ")
          _rux_buf_.append(foo)
          _rux_buf_.safe_append(" def ")
          _rux_buf_.append(bar)
          _rux_buf_.safe_append(" baz")
        }.to_s
      }
    RUBY
  end

  it 'handles rux tags inside ruby code' do
    rux_code = <<~RUX
      <Outer>
        {5.times.map do
          <Inner>What a {@thing}</Inner>
        end}
      </Outer>
    RUX

    expect(compile(rux_code)).to eq(<<~RUBY.strip)
      render(Outer.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append(5.times.map {
            render(Inner.new) { |rux_block_arg1|
              Rux.create_buffer.tap { |_rux_buf_|
                _rux_buf_.safe_append("What a ")
                _rux_buf_.append(@thing)
              }.to_s
            }
          })
        }.to_s
      }
    RUBY
  end

  it 'handles HTML tags inside ruby code' do
    rux_code = <<~RUX
      <div>
        {5.times.map do
          <p>What a {@thing}</p>
        end}
      </div>
    RUX

    expect(compile(rux_code)).to eq(<<~RUBY.strip)
      Rux.tag("div") {
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append(5.times.map {
            Rux.tag("p") {
              Rux.create_buffer.tap { |_rux_buf_|
                _rux_buf_.safe_append("What a ")
                _rux_buf_.append(@thing)
              }.to_s
            }
          })
        }.to_s
      }
    RUBY
  end

  it 'handles regular HTML tags' do
    expect(compile('<div>foo</div>')).to eq(<<~RUBY.strip)
      Rux.tag("div") {
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.safe_append("foo")
        }.to_s
      }
    RUBY
  end

  it 'handles regular HTML tags inside ruby code' do
    rux_code = <<~RUX
      <Outer>
        {5.times.map do
          <div>So {@cool}</div>
        end}
      </Outer>
    RUX

    expect(compile(rux_code)).to eq(<<~RUBY.strip)
      render(Outer.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append(5.times.map {
            Rux.tag("div") {
              Rux.create_buffer.tap { |_rux_buf_|
                _rux_buf_.safe_append("So ")
                _rux_buf_.append(@cool)
              }.to_s
            }
          })
        }.to_s
      }
    RUBY
  end

  it 'demonstrates that tags support keyword splats' do
    code = <<~RUX
      <div {**args}>foo</div>
    RUX

    expect(compile(code)).to eq(<<~RUBY.strip)
      Rux.tag("div", { **args }) {
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.safe_append("foo")
        }.to_s
      }
    RUBY
  end

  it 'demonstrates that tags support keyword arguments mixed with splats' do
    code = <<~RUX
      <div foo="bar" {**args} baz={"boo"}>foo</div>
    RUX

    expect(compile(code)).to eq(<<~RUBY.strip)
      Rux.tag("div", { foo: "bar", **args, baz: "boo" }) {
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.safe_append("foo")
        }.to_s
      }
    RUBY
  end
end
