defmodule MixAudit.Fix do
  @moduledoc """
  Provides functionality to automatically fix vulnerable dependencies by updating them to non-vulnerable versions,
  if available. The main entry point is the `call/3` function, which takes a list of vulnerabilities
  and attempts to fix them, returning a summary of the results.
  """

  @doc """
  Attempts to fix the given vulnerabilities by updating the affected packages to a non-vulnerable version.
  Returns a map with three keys:
  - `:fixed` — a list of packages that were successfully updated, with their old and new versions
  - `:manual` — a list of packages that require manual intervention, with reasons why they couldn't be auto-fixed
  - `:failed` — a list of packages for which the update process failed, with error details
  """
  def call(vulnerabilities, path, opts \\ []) do
    updater = Keyword.get(opts, :updater, &MixAudit.DependencyUpdater.call/2)
    dependency_reader = Keyword.get(opts, :dependency_reader, &MixAudit.Project.dependencies/1)

    vulnerabilities
    |> Enum.group_by(fn v -> v.dependency.package end)
    |> Enum.reduce(%{fixed: [], manual: [], failed: []}, fn {package, vulns}, acc ->
      case fix_package(package, vulns, path, updater, dependency_reader) do
        {:fixed, from, to} ->
          update_in(acc, [:fixed], &[%{package: package, from: from, to: to} | &1])

        {:manual, reason} ->
          update_in(acc, [:manual], &[%{package: package, reason: reason} | &1])

        {:failed, reason} ->
          update_in(acc, [:failed], &[%{package: package, reason: reason} | &1])
      end
    end)
  end

  defp fix_package(package, vulnerabilities, path, updater, dependency_reader) do
    current_version = List.first(vulnerabilities).dependency.version

    case find_required_minimum_patch(current_version, vulnerabilities) do
      {:error, reason} ->
        {:manual, reason}

      {:ok, minimum_patch} ->
        case updater.(package, path) do
          {:error, reason} -> {:failed, reason}
          :ok -> verify_update(package, path, current_version, minimum_patch, dependency_reader)
        end
    end
  end

  defp verify_update(package, path, current_version, minimum_patch, dependency_reader) do
    new_dep = Enum.find(dependency_reader.(path), &(&1.package == package))

    case new_dep do
      nil -> {:manual, :package_removed}
      dep -> check_new_version(dep.version, current_version, minimum_patch)
    end
  end

  defp check_new_version(version_str, current_version, minimum_patch) do
    case Version.parse(version_str) do
      {:ok, new_vsn} ->
        if Version.compare(new_vsn, minimum_patch) in [:eq, :gt] do
          {:fixed, current_version, version_str}
        else
          {:manual, :constraint_in_mix_exs}
        end

      :error ->
        {:manual, :constraint_in_mix_exs}
    end
  end

  # For each advisory, finds the minimum patched version in the same major series.
  # Returns the maximum of those per-advisory minimums — the version that fixes ALL CVEs.
  defp find_required_minimum_patch(current_vsn_str, vulnerabilities) do
    case Version.parse(current_vsn_str) do
      :error -> {:error, :malformed_version}
      {:ok, current} -> collect_per_advisory_minimums(current, vulnerabilities)
    end
  end

  defp collect_per_advisory_minimums(current, vulnerabilities) do
    vulnerabilities
    |> Enum.reduce_while({:ok, []}, fn vuln, {:ok, acc} ->
      case find_min_same_major(current, vuln.advisory.first_patched_versions) do
        {:ok, v} -> {:cont, {:ok, [v | acc]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
    |> case do
      {:ok, []} -> {:error, :no_patched_versions}
      {:ok, minimums} -> {:ok, List.last(Enum.sort(minimums, Version))}
      {:error, _} = err -> err
    end
  end

  defp find_min_same_major(_current, nil), do: {:error, :no_patched_versions}
  defp find_min_same_major(_current, []), do: {:error, :no_patched_versions}

  defp find_min_same_major(current, patched_vsn_strs) do
    same_major =
      Enum.flat_map(patched_vsn_strs, fn vsn_str ->
        case Version.parse(vsn_str) do
          {:ok, v} when v.major == current.major -> [v]
          _ -> []
        end
      end)

    case same_major do
      [] -> {:error, :requires_major_bump}
      versions -> {:ok, hd(Enum.sort(versions, Version))}
    end
  end
end
