defmodule Mix.Tasks.Deps.Audit do
  use Mix.Task

  @shortdoc "Scan for security vulnerabilities in Mix dependencies"

  @impl Mix.Task
  def run(args) do
    MixAudit.scan(args)
  end
end
