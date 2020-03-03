defmodule Mix.Tasks.Deps.Audit do
  use Mix.Task

  @shortdoc "Scan for security vulnerabilities in Mix dependencies"

  @doc false
  defdelegate run(args), to: MixAudit, as: :scan

  @doc false
  defdelegate main(args), to: MixAudit, as: :scan
end
