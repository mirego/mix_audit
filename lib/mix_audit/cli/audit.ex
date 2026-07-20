defmodule MixAudit.CLI.Audit do
  def run(opts) do
    # Synchronize the advisory mirror. The advisory database is fetched at
    # runtime with no bundled fallback, so a failed synchronization would
    # otherwise leave the audit scanning against an empty advisory set and
    # passing silently. Always fail closed: surface the git failure and exit
    # non-zero instead of reporting no vulnerabilities.
    case MixAudit.Repo.synchronize() do
      {:error, reason} ->
        IO.puts(:stderr, format_sync_error(reason))
        # Use halt/1 rather than stop/1 so the non-zero exit status is
        # guaranteed: stop/1 is asynchronous and can race with Mix's own normal
        # (status 0) shutdown, which would defeat the point of failing closed.
        # The diagnostic above is already flushed synchronously to stderr.
        System.halt(1)

      :ok ->
        audit(opts)
    end
  end

  defp audit(opts) do
    # Get and sanitize options
    path = Path.expand(Keyword.get(opts, :path, "."))
    format = Keyword.get(opts, :format)
    ignored_advisory_ids = ignored_advisory_ids(opts)
    ignored_package_names = ignored_package_names(opts)

    # Get security advisories
    advisories =
      MixAudit.Repo.read_advisories()
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

  defp format_sync_error({:git, exit_status, output}) do
    trimmed_output = String.trim(to_string(output))

    "Failed to synchronize the security advisories mirror (git exited with status #{exit_status})." <>
      if(trimmed_output == "", do: "", else: "\n" <> trimmed_output)
  end
end
