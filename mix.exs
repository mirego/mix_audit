defmodule MixAudit.MixProject do
  use Mix.Project

  @version "0.1.4"

  def project do
    [
      app: :mix_audit,
      version: @version,
      elixir: "~> 1.8",
      description: "MixAudit provides a `mix deps.audit` task to scan a project Mix dependencies for known Elixir security vulnerabilities",
      source_url: "https://github.com/mirego/mix_audit",
      homepage_url: "https://github.com/mirego/mix_audit",
      docs: [
        extras: ["README.md"],
        main: "readme",
        source_ref: "v#{@version}",
        source_url: "https://github.com/mirego/mix_audit"
      ],
      start_permanent: false,
      package: package(),
      deps: deps(),
      escript: escript()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:yaml_elixir, "~> 2.4.0"},
      {:jason, "~> 1.1"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:credo_naming, "~> 0.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    %{
      maintainers: ["Rémi Prévost"],
      licenses: ["BSD-3"],
      links: %{
        "GitHub" => "https://github.com/mirego/mix_audit"
      }
    }
  end

  def escript do
    [main_module: Mix.Tasks.Deps.Audit]
  end
end
