defmodule MixAudit.Repo do
  @url "https://github.com/mirego/elixir-security-advisories.git"

  @doc """
  Synchronizes the local advisory mirror and returns the parsed advisories.

  Synchronization failures are ignored so that a previously cloned mirror (or an
  empty result) is still usable. Callers that need to detect a failed
  synchronization should call `synchronize/0` explicitly.
  """
  def advisories do
    synchronize()

    read_advisories()
  end

  @doc """
  Synchronizes the local advisory mirror with the upstream repository.

  Returns `:ok` when the underlying `git` command succeeds, or
  `{:error, {:git, exit_status, output}}` when it fails (for example when the
  mirror directory is not writable or the network is unavailable). Because the
  advisory database is fetched at runtime with no bundled fallback, a failed
  synchronization otherwise leaves the audit scanning against an empty advisory
  set and passing silently.
  """
  def synchronize(repo_path \\ path()) do
    {output, exit_status} =
      if File.dir?(repo_path) do
        previous_path = File.cwd!()
        File.cd(repo_path)

        result = System.cmd("git", ["pull", "--rebase", "--quiet", "origin", "main"], stderr_to_stdout: true)

        File.cd(previous_path)

        result
      else
        System.cmd("git", ["clone", "--quiet", @url, repo_path], stderr_to_stdout: true)
      end

    case exit_status do
      0 -> :ok
      status -> {:error, {:git, status, output}}
    end
  end

  @doc """
  Reads and parses the advisories currently present in the local mirror without
  synchronizing first. Returns an empty list when the mirror is absent.
  """
  def read_advisories do
    package_advisories_path()
    |> Path.wildcard()
    |> Enum.map(&map_advisory/1)
  end

  defp path do
    Path.join([System.user_home(), ".local", "share", "elixir-security-advisories-mirego"])
  end

  defp package_advisories_path do
    Path.join([path(), "packages", "**", "*.yml"])
  end

  defp map_advisory(advisory_path) do
    {:ok, advisory_data} = YamlElixir.read_from_file(advisory_path)

    %MixAudit.Advisory{
      id: advisory_data["id"],
      package: advisory_data["package"],
      disclosure_date: advisory_data["disclosure_date"],
      url: advisory_data["link"],
      title: advisory_data["title"],
      description: advisory_data["description"],
      vulnerable_version_ranges: advisory_data["vulnerable_version_ranges"],
      first_patched_versions: advisory_data["first_patched_versions"],
      severity: advisory_data["severity"]
    }
  end
end
