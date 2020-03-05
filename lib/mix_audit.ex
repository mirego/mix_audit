defmodule MixAudit do
  require Logger

  def scan(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [help: :boolean, format: :string, path: :string])

    if opts[:help] do
      IO.puts("Usage: mix deps.audit [options]")
      IO.puts("")
      IO.puts("Example: $ mix deps.audit --path=/home/projects/my_app --format=json")
      IO.puts("")
      IO.puts("Options:")
      IO.puts("--path       The root path of the project to audit")
      IO.puts("--format     The format of the report to generate (human, json)")
      IO.puts("")
      System.halt(0)
    end

    # Get and sanitize options
    path = Path.expand(Keyword.get(opts, :path, "."))
    format = Keyword.get(opts, :format)

    # Synchronize and get security advisories
    advisories = MixAudit.Repo.advisories()

    # Get project dependencies
    dependencies = MixAudit.Project.dependencies(path)

    # Generate a security report
    report = MixAudit.Audit.report(dependencies, advisories)

    # Format the report according to the specified format
    formatted_report = MixAudit.Formatting.format(report, format)

    # Output the result
    IO.puts(String.trim(formatted_report))

    unless report.pass do
      System.halt(1)
    end
  end
end
