require 'spec_helper'

describe 'html safety', type: :parser do
  it 'escapes HTML entities in strings' do
    expect(compile('<Hello>"foo"</Hello>')).to eq(<<~RUBY.strip)
      render(Hello.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.safe_append("&quot;foo&quot;")
        }.to_s
      }
    RUBY
  end
end
