require 'spec_helper'

describe 'slots', type: :parser do
  it 'correctly transforms slot components into slot methods' do
    code = <<~RUX
      <TableComponent>
        <WithRow>
          <WithColumn>Foo 1</WithColumn>
        </WithRow>
        <WithRow>
          <WithColumn>Foo 2</WithColumn>
        </WithRow>
      </TableComponent>
    RUX
    expect(compile(code)).to eq(<<~RUBY.strip)
      render(TableComponent.new) { |rux_block_arg0|
        Rux.create_buffer.tap { |_rux_buf_|
          _rux_buf_.append((rux_block_arg0.with_row { |rux_block_arg1|
            Rux.create_buffer.tap { |_rux_buf_|
              _rux_buf_.append((rux_block_arg1.with_column { |rux_block_arg2|
                Rux.create_buffer.tap { |_rux_buf_|
                  _rux_buf_.safe_append("Foo 1")
                }.to_s
              }; nil))
            }.to_s
          }; nil))
          _rux_buf_.append((rux_block_arg0.with_row { |rux_block_arg1|
            Rux.create_buffer.tap { |_rux_buf_|
              _rux_buf_.append((rux_block_arg1.with_column { |rux_block_arg2|
                Rux.create_buffer.tap { |_rux_buf_|
                  _rux_buf_.safe_append("Foo 2")
                }.to_s
              }; nil))
            }.to_s
          }; nil))
        }.to_s
      }
    RUBY
  end
end
