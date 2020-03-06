<div align="center">
  <img src="https://user-images.githubusercontent.com/11348/75812982-32921e80-5d5d-11ea-9c3b-ad46fd6005f9.png" width="500" />
  <br /><br />
  <code>MixAudit</code> provides a <code>mix deps.audit</code> task to scan Mix dependencies for security vulnerabilities.
  <br />
  It draw its inspiration from tools like <a href="https://docs.npmjs.com/cli/audit"><code>npm audit</code></a> and <a href="https://github.com/rubysec/bundler-audit"><code>bundler-audit</code></a>.
  <br /><br />
  <a href="https://github.com/mirego/mix_audit/actions?query=workflow%3ACI+branch%3Amaster+event%3Apush"><img src="https://github.com/mirego/mix_audit/workflows/CI/badge.svg?branch=master&event=push" /></a>
  <a href="https://hex.pm/packages/mix_audit"><img src="https://img.shields.io/hexpm/v/mix_audit.svg" /></a>
</div>

## Installation

### Project dependency

Add `mix_audit` to the `deps` function in your project’s `mix.exs` file:

```elixir
defp deps do
  [
    {:mix_audit, "~> 0.1", only: [:dev, :test], runtime: false}
  ]
end
```

Then run `mix do deps.get, deps.compile` inside your project’s directory.

### Local `escript`

If you do not wish to include `mix_audit` in your project dependencies, you can install it as global `escript`:

```bash
$ mix escript.install hex mix_audit
…
* creating …/.mix/escripts/mix_audit
```

The only difference is that instead of using the `mix deps.audit` task, you will have to use the created executable.

## Usage

To generate a security report, you can use the `deps.audit` Mix task:

```bash
$ mix deps.audit
```

### Options

| Option                   | Type   | Default             | Description                                                  |
| ------------------------ | ------ | ------------------- | ------------------------------------------------------------ |
| `--path`                 | String | _Current directory_ | The root path of the project to audit                        |
| `--format`               | String | `"human"`           | The format of the report to generate (`"json"` or `"human"`) |
| `--ignore-advisory-ids`  | String | `""`                | Comma-separated list of advisory IDs to ignore               |
| `--ignore-package-names` | String | `""`                | Comma-separated list of package names to ignore              |

## Example

<img src="https://user-images.githubusercontent.com/11348/76112291-ea1e6f00-5faf-11ea-8337-6656d765b7fc.png">

## How does it work?

MixAudit builds two lists when it’s executed in a project:

1. A list of security advisories fetched from the community-maintained [`elixir-security-advisories`](https://github.com/dependabot/elixir-security-advisories) repository
2. A list of Mix dependencies from the various `mix.lock` files in the project

Then, it loops through each project dependency and tries to find security advisories that apply to it (through its package name) and that match its version specification (through the advisory patched and unaffected version policies).

If one is found, a **vulnerability** (the combination of a **security advisory** and a **project dependency**) is then added to the report.

The task will exit with a `0` status only if the report _passes_ (ie. it reports no vulnerabilities). Otherwise, it will exit with a `1` status.

## License

`MixAudit` is © 2020 [Mirego](https://www.mirego.com) and may be freely distributed under the [New BSD license](http://opensource.org/licenses/BSD-3-Clause). See the [`LICENSE.md`](https://github.com/mirego/mix_audit/blob/master/LICENSE.md) file.

The detective hat logo is based on [this lovely icon by Vectors Point](https://thenounproject.com/term/detective/1883300), from The Noun Project. Used under a [Creative Commons BY 3.0](http://creativecommons.org/licenses/by/3.0/) license.

## About Mirego

[Mirego](https://www.mirego.com) is a team of passionate people who believe that work is a place where you can innovate and have fun. We’re a team of [talented people](https://life.mirego.com) who imagine and build beautiful Web and mobile applications. We come together to share ideas and [change the world](http://www.mirego.org).

We also [love open-source software](https://open.mirego.com) and we try to give back to the community as much as we can.
