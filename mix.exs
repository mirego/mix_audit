defmodule MixAudit.MixProject do
  use Mix.Project

  def project do
    [
      app: :mix_audit,
      version: "0.0.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
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
      {:ecto, "2.2.0"},
      {:yaml_elixir, "~> 2.4.0"}
    ]
  end
end
