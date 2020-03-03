<div align="center">
  <img src="https://user-images.githubusercontent.com/11348/75812982-32921e80-5d5d-11ea-9c3b-ad46fd6005f9.png" width="500" />
  <p><br />MixAudit provides a <code>mix deps.audit</code> task to scan Mix dependencies for security vulnerabilities.</p>
</div>

## Warning

⚠️ **This project is currently under development, it is _not ready_ for production use yet.** ⚠️

## Installation

Add `mix_audit` to the `deps` function in your project’s `mix.exs` file:

```elixir
defp deps do
  [
    …,
    {:mix_audit, "~> 1.0", only: [:dev, :test], runtime: false}
  ]
end
```

Then run `mix do deps.get, deps.compile` inside your project’s directory.

You can also use `mix archive.install hex mix_audit` to install the package as standalone.

## Usage

```bash
$ mix deps.audit
```

## License

`MixAudit` is © 2020 [Mirego](https://www.mirego.com) and may be freely distributed under the [New BSD license](http://opensource.org/licenses/BSD-3-Clause). See the [`LICENSE.md`](https://github.com/mirego/mix_audit/blob/master/LICENSE.md) file.

The detective hat logo is based on [this lovely icon by Vectors Point](https://thenounproject.com/term/detective/1883300), from The Noun Project. Used under a [Creative Commons BY 3.0](http://creativecommons.org/licenses/by/3.0/) license.

## About Mirego

[Mirego](https://www.mirego.com) is a team of passionate people who believe that work is a place where you can innovate and have fun. We’re a team of [talented people](https://life.mirego.com) who imagine and build beautiful Web and mobile applications. We come together to share ideas and [change the world](http://www.mirego.org).

We also [love open-source software](https://open.mirego.com) and we try to give back to the community as much as we can.
