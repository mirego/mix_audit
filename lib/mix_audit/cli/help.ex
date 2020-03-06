defmodule MixAudit.CLI.Help do
  def run(_opts) do
    IO.puts("Usage: mix deps.audit [options]")
    IO.puts("")
    IO.puts("Example: $ mix deps.audit --path=/home/projects/my_app --format=json")
    IO.puts("")
    IO.puts("Options:")
    IO.puts("--path                  The root path of the project to audit")
    IO.puts("--format                The format of the report to generate (human, json)")
    IO.puts("--ignore-advisory-ids   A comma-separated list of advisory IDs to ignore")
    IO.puts("--ignore-package-names  A comma-separated list of package names to ignore")
    IO.puts("")
    System.halt(0)
  end
end
