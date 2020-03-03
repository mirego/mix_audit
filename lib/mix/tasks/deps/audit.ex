defmodule Mix.Tasks.Deps.Audit do
  use Mix.Task

  defdelegate main(args), to: __MODULE__, as: :run

  @shortdoc "Scan for security vulnerabilities in Mix dependencies"

  @impl Mix.Task
  def run(args) do
    MixAudit.scan(args)
  end
end
