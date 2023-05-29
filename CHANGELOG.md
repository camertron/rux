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
