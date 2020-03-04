defmodule MixAudit do
  require Logger

  def scan(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [format: :string, path: :string])

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
