defmodule Mix.Tasks.Deps.Audit do
  use Mix.Task

  @shortdoc "Scan for security vulnerabilities in Mix dependencies (use `--help` for options)"
  @moduledoc @shortdoc

  @doc false
  defdelegate run(args), to: MixAudit.CLI

  @doc false
  defdelegate main(args), to: MixAudit.CLI, as: :run
end
