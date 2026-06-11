defmodule MixAudit.CLI.Audit do
  def run(opts) do
    # Get and sanitize options
    path = Path.expand(Keyword.get(opts, :path, "."))
    format = Keyword.get(opts, :format)
    fix = Keyword.get(opts, :fix, false)
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

    if fix && not report.pass do
      fix_results = MixAudit.Fix.call(report.vulnerabilities, path)
      print_fix_summary(fix_results)

      all_fixed = Enum.empty?(fix_results.manual) and Enum.empty?(fix_results.failed)
      unless all_fixed, do: System.halt(1)
    else
      unless report.pass, do: System.halt(1)
    end
  end

  defp print_fix_summary(%{fixed: fixed, manual: manual, failed: failed}) do
    IO.puts("")
    IO.puts("Fix summary:")

    unless Enum.empty?(fixed) do
      IO.puts("  Fixed (#{length(fixed)}):")

      Enum.each(fixed, fn %{package: pkg, from: from, to: to} ->
        IO.puts("    #{pkg}: #{from} -> #{to}")
      end)
    end

    unless Enum.empty?(manual) do
      IO.puts("  Could not auto-fix (#{length(manual)}):")

      Enum.each(manual, fn %{package: pkg, reason: reason} ->
        IO.puts("    #{pkg}: #{format_manual_reason(reason)}")
      end)
    end

    unless Enum.empty?(failed) do
      IO.puts("  Update failed (#{length(failed)}):")

      Enum.each(failed, fn %{package: pkg, reason: {code, output}} ->
        IO.puts("    #{pkg}: exited with code #{code} — #{String.trim(output)}")
      end)
    end
  end

  defp format_manual_reason(:requires_major_bump),
    do: "patched version requires a major version bump — update manually"

  defp format_manual_reason(:no_patched_versions),
    do: "no patched version listed in advisory — update manually"

  defp format_manual_reason(:constraint_in_mix_exs),
    do: "version constraint in mix.exs prevents update — loosen the constraint and re-run"

  defp format_manual_reason(:malformed_version),
    do: "installed version string could not be parsed — update manually"

  defp format_manual_reason(:package_removed),
    do: "package disappeared from the lockfile after update — inspect mix.lock manually"

  defp format_manual_reason(reason), do: inspect(reason)

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
