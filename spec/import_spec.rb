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
end
