defmodule MixAudit.CLI.Audit do
  def run(opts) do
    # Get and sanitize options
    path = Path.expand(Keyword.get(opts, :path, "."))
    format = Keyword.get(opts, :format)
    ignored_advisory_ids = ignored_advisory_ids(opts)
    ignored_package_names = ignored_package_names(opts)

    # Synchronize and get security advisories
    advisories =
      MixAudit.Repo.advisories()
      |> Enum.reject(&(&1.id in ignored_advisory_ids))
      |> Enum.group_by(& &1.package)

    # Get project dependencies
    dependencies =
      path
      |> MixAudit.Project.dependencies()
      |> Enum.reject(&(&1.package in ignored_package_names))

    # Generate a security report
    report = MixAudit.Audit.report(dependencies, advisories)

    # Format the report according to the specified format
    formatted_report = MixAudit.Formatting.format(report, format)

    # Output the result
    IO.puts(String.trim(formatted_report))

    unless report.pass do
      System.stop(1)
    end
  end

  defp ignored_advisory_ids(opts) do
    ignored_ids_from_cli = ignored_advisory_ids_from_cli(opts)
    ignored_ids_from_file = ignored_advisory_ids_from_file(opts)

    Enum.uniq(ignored_ids_from_cli ++ ignored_ids_from_file)
  end

  defp ignored_advisory_ids_from_cli(opts) do
    opts
    |> Keyword.get(:ignore_advisory_ids, "")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end

  def ignored_advisory_ids_from_file(opts) do
    case Keyword.get(opts, :ignore_file) do
      nil ->
        []

      ignore_file ->
        ignore_file
        |> File.read!()
        |> String.split("\n")
        |> Enum.reject(fn line -> String.starts_with?(line, "#") || String.trim(line) == "" end)
    end
  end

  defp ignored_package_names(opts) do
    opts
    |> Keyword.get(:ignore_package_names, "")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end
end
