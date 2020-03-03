defmodule MixAudit.MixProject do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :mix_audit,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      docs: [
        extras: ["README.md"],
        main: "readme",
        source_ref: "v#{@version}",
        source_url: "https://github.com/mirego/mix_audit"
      ],
      description:
        "MixAudit provides a `mix deps.audit` task to scan Mix dependencies for security vulnerabilities.",
      source_url: "https://github.com/mirego/mix_audit",
      homepage_url: "https://github.com/mirego/mix_audit",
      docs: [
        extras: ["README.md"],
        main: "readme",
        source_ref: "v#{@version}",
        source_url: "https://github.com/mirego/mix_audit"
      ],
      package: package(),
      start_permanent: false,
      deps: deps()
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
      {:ex_doc, ">= 0.0.0", only: :dev}
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
end
