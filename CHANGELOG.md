# 1.3.0
* Various parser and codegen fixes to more completely support the rux syntax.
* Add ignore file support to `ruxc` via the onload gem (which is also used by rux-rails).
  - Pass the `--ignore-path=PATH` flag to add all generated files to the given ignore file, eg. a .gitignore.
* Add the `underscore_attributes` option to `Rux.to_ruby` and `Rux::File#to_ruby`.
  - By default, rux converts dasherized attributes to underscored ones, eg `<FooComponent foo-bar="baz">` becomes `FooComponent.new(foo_bar: "baz")`.
  - Pass `underscore_attributes: false` to prevent attribute transformation.
* Sourcemap support
  - Pass `--emit-sourcemaps` to `ruxc` to automatically write them to disk.

# 1.2.0
* Improve output safety.
  - HTML tags are now automatically escaped when they come from Ruby code.
* Add fragment support.
  - Analogous to JSX fragments, eg. `<>foo</>`.
* Add keyword argument support in HTML attributes.
  - Eg. `<div {**kwargs} bar="baz">boo</div>`.
* Add ViewComponent slot support.
  - Works via pseudo components that begin with `With`, eg. `<MySlotComponent><WithItem>Item</WithItem></MySlotComponent>`.
* Allow printing `ruxc` results to STDOUT.
* Support for unquoted attributes.
* Drop explicit support for Ruby versions < 3.

# 1.1.2
* Don't slugify HTML attributes in the tag builder either.

# 1.1.1
* Don't slugify HTML attributes.
  - Previously rux would emit `<div data-foo="bar">` as `<div data_foo="bar">` because it treated HTML attributes as if they were being passed as Ruby arguments, which don't allow dashes. If these arguments are passed to a component initializer, then they must be slugified, but HTML attributes shouldn't be affected.

# 1.1.0
* Remove newlines between elements. (@aalin, #3)

## 1.0.3
* Use modern AST format.
* Switch back to unparser v0.6.

## 1.0.2
* Fix bug causing `ArgumentError`s under Ruby 3.0.
  - Related: https://github.com/mbj/unparser/issues/254

## 1.0.1
* Fix bug in default buffer implementation causing `TypeError`s when attempting to shovel in arrays.

## 1.0.0
* Birthday!
