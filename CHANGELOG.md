# Changelog

## [v1.2.0](http://github.com/sbsoftware/js.cr/releases/tag/v1.2.0)

## Features
* Local variables are recognized as such (#15)
* Empty array literals can be assigned to variables (#16)

## Bugs
* Crystal namespaces are not reflected in JS class names (#14)
* `#to_js_ref` doesn't work for call arguments

## [v1.1.1](https://github.com/sbsoftware/js.cr/releases/tag/v1.1.1)

## Bugs
* Multiple expressions in if/else blocks are not evaulated (#10)
* Operators ending with "=" are handled as assignments (#11)
* Object property lookup is not transpiled correctly (#12)

## [v1.1.0](https://github.com/sbsoftware/js.cr/releases/tag/v1.1.0)

## Features
* Impossible variable/method names for Crystal can be aliased
* `JS::File` is introduced as generalization of `JS::Module`
* `JS::Classes` can be instantiated
* `If`s are transpiled correctly (#6)
* Return statements are transpiled correctly
* Hash literals are transformed into JavaScript objects (#7)
* Hash value assignment is transpiled correctly (#5)
* `#to_js_ref` can be used with Strings (#9)

## Bugs
* Function names are transformed to underscore (#3)
* `new` does not work with unknown constants (#2)
* Blocks as anonymous function parameters don't work with other arguments (#4)
* `_literal_js` does not work for call arguments (#8)
* Math operators don't work (#1)

## [v1.0.2](https://github.com/sbsoftware/js.cr/releases/tag/v1.0.2)

### Bugs

- Macro `if`s and `for`s don't work with JS code

## [v1.0.1](https://github.com/sbsoftware/js.cr/releases/tag/v1.0.1)

### Bugs

- Macro expressions are printed out literally

## [v1.0.0](https://github.com/sbsoftware/js.cr/releases/tag/v1.0.0)

Initial Release
