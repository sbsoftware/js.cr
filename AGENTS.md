# Repository Guidelines

## Project Structure & Module Organization
- `src/js.cr` is the shard entrypoint; core types live under `src/js/` (e.g., `code.cr`, `function.cr`, `class.cr`, `module.cr`, `file.cr`, `method.cr`).
- `src/ext/` contains Crystal core extensions used by the JS builders.
- `spec/` holds tests and helpers (see `spec/spec_helper.cr`).

## Build, Test, and Development Commands
- `shards install` — install Crystal shard dependencies (none currently, but keep in sync with `shard.yml`).
- `crystal spec` — run the full test suite; `crystal spec spec/<file>_spec.cr` for a focused run.
- `crystal spec --error-trace` — helpful when debugging macro or compiler errors.
- `crystal tool format` or `crystal tool format --check src spec` — format and verify style before PRs.
- `crystal build src/js.cr -o bin/js` — optional local build if you want a compiled artifact.

## Coding Style & Naming Conventions
- Follow standard Crystal formatting: 2-space indentation, LF line endings, final newline; rely on `crystal tool format`.
- Naming: `CamelCase` for modules/classes/types; `snake_case` for files, methods, and variables.
- Prefer self-descriptive names; document public APIs only when behavior is non-obvious.
- JS output is intentionally whitespace-light; specs often normalize with `String#squish` (see `spec/spec_helper.cr`).

## Testing Guidelines
- Use Crystal’s `spec` framework; place specs in `spec/` and name files `*_spec.cr`.
- Keep examples minimal and deterministic; cover the happy path plus one failure/edge case where feasible.
