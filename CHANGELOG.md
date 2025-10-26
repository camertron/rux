# 1.3.0
* Automatically add generated files to an ignore file, eg. .gitignore.
  - Pass the --ignore-path=PATH flag to ruxc to indicate the file to update.
* Add the ruxlex executable that prints parser tokens for debugging purposes.
* Preserve Ruby comments in generated files.
* Fix the `as:` argument, which was being improperly generated in earlier versions.
* General parser improvements.
  - Allows fragments to be nested within other tags.
  - Allows tags after ruby code in branch structures like `if..else`.
* Allows HTML attributes to start with `@`.

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
