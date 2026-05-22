defmodule MixAudit.HexAdvisories do
  def advisories(config \\ :hex_core.default_config()) do
    with {:ok, {200, _headers, %{packages: packages}}} <- :hex_repo.get_versions(config) do
      packages
      |> Enum.filter(&has_advisories?/1)
      |> Enum.flat_map(&package_advisories(config, field(&1, :name)))
    else
      _ -> []
    end
  end

  def map_package_advisories(package, releases, advisories) do
    advisories
    |> Enum.with_index()
    |> Enum.map(fn {advisory, index} ->
      affected_versions = affected_versions(releases, index)

      %MixAudit.Advisory{
        id: advisory_id(advisory),
        package: package,
        disclosure_date: nil,
        url: field(advisory, :html_url) || field(advisory, :api_url),
        title: field(advisory, :summary) || advisory_id(advisory),
        description: field(advisory, :summary) || "",
        vulnerable_version_ranges: Enum.map(affected_versions, &"= #{&1}"),
        first_patched_versions: first_patched_versions(releases, index, affected_versions),
        severity: severity(advisory)
      }
    end)
    |> Enum.reject(&Enum.empty?(&1.vulnerable_version_ranges))
  end

  defp package_advisories(config, package) do
    case :hex_repo.get_package(config, package) do
      {:ok, {200, _headers, %{releases: releases, advisories: advisories}}} ->
        map_package_advisories(package, releases, advisories)

      _ ->
        []
    end
  end

  defp has_advisories?(package) do
    package
    |> field(:with_advisories)
    |> empty?()
    |> Kernel.not()
  end

  defp affected_versions(releases, advisory_index) do
    releases
    |> Enum.filter(&has_advisory_index?(&1, advisory_index))
    |> Enum.map(&field(&1, :version))
  end

  defp first_patched_versions(_releases, _advisory_index, []), do: []

  defp first_patched_versions(releases, advisory_index, affected_versions) do
    highest_affected_version = Enum.max(affected_versions, Version)

    releases
    |> Enum.reject(&has_advisory_index?(&1, advisory_index))
    |> Enum.map(&field(&1, :version))
    |> Enum.filter(&(Version.compare(&1, highest_affected_version) == :gt))
    |> Enum.sort(Version)
    |> Enum.take(1)
  end

  defp has_advisory_index?(release, advisory_index) do
    release
    |> field(:advisory_indexes)
    |> Enum.member?(advisory_index)
  end

  defp advisory_id(advisory) do
    field(advisory, :id) || List.first(field(advisory, :aliases) || [])
  end

  defp severity(advisory) do
    case field(advisory, :severity) do
      nil ->
        nil

      severity when is_atom(severity) ->
        severity
        |> Atom.to_string()
        |> String.replace_prefix("SEVERITY_", "")
        |> String.downcase()

      severity ->
        to_string(severity)
    end
  end

  defp empty?(nil), do: true
  defp empty?(collection), do: Enum.empty?(collection)

  defp field(map, key) when is_map(map) do
    Map.get(map, key) || Map.get(map, to_string(key))
  end
end
