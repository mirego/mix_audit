# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 2.1.2 (2024-01-08)

- Add better support for Elixir 1.16, thank you @cgrothaus! ([#26](https://github.com/mirego/mix_audit/pull/26))

## 2.1.1 (2023-06-21)

- Remove `rescue` in `Repo.synchronize/0` to avoid swallowing error messages that can be useful for debugging issues ([#23](https://github.com/mirego/mix_audit/pull/23))
- Add support for Elixir 1.15 in workflows
- Upgrade `ex_doc` and `earmark`
- Update Credo configuration with recent checks

## 2.1.0 (2022-12-12)

- Update `yaml_elixir` dependency to 2.9

## 2.0.2 (2022-11-16)

### Updated

- Update default branch for the repository
- Update [default branch reference](https://github.com/mirego/elixir-security-advisories/pull/4) for elixir-security-advisories

## 2.0.1 (2022-08-23)

### Updated

- Add `severity` to output formats ([#14](https://github.com/mirego/mix_audit/pull/14))

## 2.0.0 (2022-08-09)

### Updated

- Replace [`dependabot/elixir-security-advisories`](https://github.com/dependabot/elixir-security-advisories) with [`mirego/elixir-security-advisories`](https://github.com/mirego/elixir-security-advisories).

## 1.0.1 (2022-04-07)

### Added

- Upgrade `publish` workflow to use Elixir 1.13

## 1.0.0 (2021-08-20)

- First official 1.x version

## 0.1.2 (2020-03-09)

### Added

- Project changelog (`CHANGELOG.md`)

### Updated

- Only support `hex` dependencies (#2)

## 0.1.1 (2020-03-06)

- Initial release
