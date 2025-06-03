# Changelog
All notable changes to this project will be documented in this file.

* The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
* This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

### Fixed
- Fix docs and readme: link typo, examples of `accessible_by` usage.
- Updated dependencies.

## [v0.2.3]
### Fixed
- Fix `Ecto.Query.dynamic_expr()` type naming after Ecto version upgrade.
- Fix any other issues indicated by Credo and Dialyzer (#19).

## [v0.2.2]
### Fixed
- Fix warnings affecting compilation and runtime (#16).

## [v0.2.1]
### Fixed
- Fix query building when no joins are specified (#14).

## [v0.2.0]
### Added
- Allow nesting association-based conditions (curiosum-dev/permit#36). For example, predicates such as `read(Item, user: [id: user_id])` can now be written.

## [v0.1.1]
### Fixed
- Fix action traversal issue (#4).

## [v0.1.0]
Initial release.
