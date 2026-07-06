defmodule MixAudit.HexAdvisories do
  def advisories(config \\ :hex_core.default_config()) do
    case :hex_repo.get_versions(config) do
      {:ok, {200, _headers, %{packages: packages}}} ->
        packages
        |> Enum.filter(&has_advisories?/1)
        |> Enum.flat_map(&package_advisories(config, field(&1, :name)))

      _ ->
        []
    end
  end

  def map_package_advisories(package, releases, advisories) do
    advisories
    |> Enum.with_index()
    |> advisory_groups()
    |> Enum.map(fn %{advisory: advisory, indexes: indexes} ->
      affected_versions = affected_versions(releases, indexes)

      %MixAudit.Advisory{
        id: advisory_id(advisory),
        package: package,
        disclosure_date: nil,
        url: field(advisory, :html_url) || field(advisory, :api_url),
        title: field(advisory, :summary) || advisory_id(advisory),
        description: field(advisory, :summary) || "",
        vulnerable_version_ranges: Enum.map(affected_versions, &"= #{&1}"),
        first_patched_versions: first_patched_versions(releases, indexes, affected_versions),
        severity: severity(advisory)
      }
    end)
    |> Enum.reject(&Enum.empty?(&1.vulnerable_version_ranges))
  end

  defp advisory_groups(indexed_advisories) do
    grouped_advisories =
      Enum.map(indexed_advisories, fn {advisory, index} ->
        advisory
        |> groupable_advisory()
        |> Map.put(:mix_audit_advisory, advisory)
        |> Map.put(:mix_audit_index, index)
      end)

    grouped_advisories
    |> :hex_advisory.group_for_display()
    |> Enum.map(fn grouped_advisory ->
      identifiers = identifiers(grouped_advisory)

      indexes =
        grouped_advisories
        |> Enum.filter(&(not MapSet.disjoint?(identifiers, identifiers(&1))))
        |> Enum.map(& &1.mix_audit_index)

      %{advisory: grouped_advisory.mix_audit_advisory, indexes: indexes}
    end)
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

  defp identifiers(advisory) do
    advisory
    |> aliases()
    |> Enum.map(&to_binary_id/1)
    |> MapSet.new()
  end

  defp aliases(advisory) do
    [field(advisory, :id) | field(advisory, :aliases) || []]
    |> Enum.map(&alias_id/1)
    |> Enum.reject(&is_nil/1)
  end

  defp groupable_advisory(advisory) do
    %{
      id: to_binary_id(field(advisory, :id)),
      aliases: Enum.map(field(advisory, :aliases) || [], &to_binary_id/1)
    }
  end

  defp alias_id(%{id: id}), do: id
  defp alias_id(%{"id" => id}), do: id
  defp alias_id(id), do: id

  defp ghsa_id?(id) when is_binary(id), do: String.starts_with?(id, "GHSA-")
  defp ghsa_id?(_id), do: false

  defp to_binary_id(id) when is_binary(id), do: id
  defp to_binary_id(id), do: to_string(id)

  defp affected_versions(releases, advisory_indexes) do
    releases
    |> Enum.filter(&has_advisory_index?(&1, advisory_indexes))
    |> Enum.map(&field(&1, :version))
  end

  defp first_patched_versions(_releases, _advisory_indexes, []), do: []

  defp first_patched_versions(releases, advisory_indexes, affected_versions) do
    highest_affected_version = Enum.max(affected_versions, Version)

    releases
    |> Enum.reject(&has_advisory_index?(&1, advisory_indexes))
    |> Enum.map(&field(&1, :version))
    |> Enum.filter(&(Version.compare(&1, highest_affected_version) == :gt))
    |> Enum.sort(Version)
    |> Enum.take(1)
  end

  defp has_advisory_index?(release, advisory_indexes) do
    advisory_indexes = MapSet.new(advisory_indexes)

    release
    |> field(:advisory_indexes)
    |> MapSet.new()
    |> MapSet.disjoint?(advisory_indexes)
    |> Kernel.not()
  end

  defp advisory_id(advisory) do
    Enum.find(aliases(advisory), &ghsa_id?/1) ||
      field(advisory, :id) ||
      List.first(field(advisory, :aliases) || [])
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
