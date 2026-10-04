# Changelog

## v1.9.0

### Breaking changes

- Crystal `==` and `!=` now emit JavaScript strict equality operators `===` and `!==` in all expressions. Loose equality is no longer emitted by default. Code that intentionally relied on JavaScript coercion must normalize operand types before comparison or use explicit JavaScript via `_literal_js` outside strict mode.
- JavaScript objects and arrays use reference equality with `===` and `!==`, unlike Crystal containers whose `==` commonly compares values. Review generated comparisons involving containers when upgrading.
