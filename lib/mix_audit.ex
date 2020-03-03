defmodule MixAudit do
  require Logger

  def scan(path) do
    # Synchronize and get security advisories
    advisories = MixAudit.Repo.advisories()

    # Get project dependencies
    dependencies = MixAudit.Project.dependencies(path)

    # Generate a security report
    report = MixAudit.Audit.report(dependencies, advisories)

    # Print everything for now
    IO.inspect(report)

    unless report.pass do
      System.halt(1)
    end
  end
end
