require 'spec_helper'

describe Rux::Parser do
  it 'imports a bare constant' do
    expect("import Foo").to import(:Foo)
  end

  it 'imports a bare constant with an alias' do
    expect("import Foo as Bar").to import(:Foo).as(:Bar)
  end

  it 'imports a constant from elsewhere' do
    expect("import {Foo} from Baz").to import(:Foo).from(:Baz)
  end

  it 'imports a constant with an alias from elsewhere' do
    expect("import {Foo as Bar} from Baz").to import(:Foo).as(:Bar).from(:Baz)
  end

  it 'imports multiple bare constants' do
    rux_code = <<~RUX
      import Foo
      import Bar
    RUX

    expect(rux_code).to import(:Foo).and(import(:Bar))
  end

  it 'imports multiple bare constants separated by a newline' do
    rux_code = <<~RUX
      import Foo

      import Bar
    RUX

    expect(rux_code).to import(:Foo).and(import(:Bar))
  end

  it 'imports multiple bare constants separated by ruby code' do
    rux_code = <<~RUX
      import Foo
      5.times { puts "Hey!" }
      import Bar
    RUX

    expect(rux_code).to import(:Foo).and(import(:Bar))
  end

  it 'imports multiple aliased constants' do
    rux_code = <<~RUX
      import {Foo as Faa} from Fuu
      import {Bar as Baa} from Buu
    RUX

    expect(rux_code).to(
      import(:Foo).as(:Faa).from(:Fuu).and(
        import(:Bar).as(:Baa).from(:Buu)
      )
    )
  end

  it 'imports multiple aliased constants from the same const' do
    rux_code = <<~RUX
      import {Foo as Faa, Bar as Baa} from Fuu
    RUX

    expect(rux_code).to(
      import(:Foo).as(:Faa).from(:Fuu).and(
        import(:Bar).as(:Baa).from(:Fuu)
      )
    )
  end

  it 'imports multiple aliased constants from the multiple consts' do
    rux_code = <<~RUX
      import {Foo as Faa, Bar as Baa} from Fuu
      import {Goo as Gaa, Zar as Zaa} from Zuu
    RUX

    expect(rux_code).to(
      import(:Foo).as(:Faa).from(:Fuu)
        .and(import(:Bar).as(:Baa).from(:Fuu))
        .and(import(:Goo).as(:Gaa).from(:Zuu))
        .and(import(:Zar).as(:Zaa).from(:Zuu))
    )
  end

  it 'replaces imported constants' do
    rux_code = <<~RUX
      import {Bar} from Foo

      Bar.do_something
    RUX

    expect(compile(rux_code)).to eq(<<~RUBY.strip)
      Foo::Bar.do_something
    RUBY
  end

  it 'replaces imported, aliased constants' do
    rux_code = <<~RUX
      import {Bar as Boo} from Foo

      Boo.do_something
    RUX

    expect(compile(rux_code)).to eq(<<~RUBY.strip)
      Foo::Bar.do_something
    RUBY
  end

  it 'replaces imported, aliased, nested constants' do
    rux_code = <<~RUX
      import {Bar as Boo} from Foo::Goo

      Boo.do_something
    RUX

    expect(compile(rux_code)).to eq(<<~RUBY.strip)
      Foo::Goo::Bar.do_something
    RUBY
  end

  it "raises an exception if a constant hasn't been imported" do
    rux_code = <<~RUX
      Foo.do_something
    RUX

    expect { compile(rux_code) }.to(
      raise_error(Rux::Imports::MissingConstantError) do |e|
        expect(e.missing_const).to eq([:Foo])
      end
    )
  end

  it 'does not error when encountering constant references defined in the same file' do
    rux_code = <<~RUX
      class Foo
      end

      Foo.new
    RUX

    expect { compile(rux_code) }.to_not raise_error
  end

  it 'does not error when encountering nested constant references defined in the same file' do
    rux_code = <<~RUX
      module Foo
        class Bar
        end
      end

      Foo::Bar.new
    RUX

    expect { compile(rux_code) }.to_not raise_error
  end

  it 'does not error when encountering constant references at different nesting levels defined in the same file' do
    rux_code = <<~RUX
      module Foo
        class Bar
        end

        Bar.new
      end

      Foo::Bar.new
    RUX

    expect { compile(rux_code) }.to_not raise_error
  end

  it 'errors when encountering constant references at the wrong nesting level defined in the same file' do
    rux_code = <<~RUX
      module Foo
        class Bar
        end

        Bar.new
      end

      Bar.new
    RUX

    expect { compile(rux_code) }.to(
      raise_error(Rux::Imports::MissingConstantError) do |e|
        expect(e.missing_const).to eq([:Bar])
      end
    )
  end
end
