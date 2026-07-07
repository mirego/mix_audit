defmodule MixAudit.Repo do
  @url "https://github.com/mirego/elixir-security-advisories.git"

  def advisories do
    synchronize()

    package_advisories_path()
    |> Path.wildcard()
    |> Enum.map(&map_advisory/1)
  end

  defp synchronize do
    repo_path = path()

    repo_path
    |> git_commands(File.dir?(repo_path))
    |> run_git_commands()
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

  defp git_commands(repo_path, repo_exists?) do
    if repo_exists? do
      # System.cmd's `cd` option scopes the working directory to the git child process, not
      # the whole BEAM, so a concurrent process writing a relative path can't land files
      # inside this clone.
      #
      # The clone is a throwaway mirror, so force-sync it to `origin/main` with `fetch` +
      # `reset --hard`: it never aborts on a dirty or diverged working tree, and works on
      # git 1.8 and up.
      [
        {["fetch", "--quiet", "origin", "main"], [cd: repo_path]},
        {["reset", "--hard", "--quiet", "origin/main"], [cd: repo_path]}
      ]
    else
      [{["clone", "--quiet", @url, repo_path], []}]
    end
  end

  # Run each command in turn, stopping at the first failure: e.g. don't `reset --hard` onto
  # origin/main if the `fetch` didn't land. A failure is non-fatal (the audit falls back to
  # the advisories already on disk), so we stop rather than raise.
  defp run_git_commands(commands) do
    Enum.reduce_while(commands, :ok, fn {args, opts}, :ok ->
      case System.cmd("git", args, opts) do
        {_output, 0} -> {:cont, :ok}
        {_output, _status} -> {:halt, :error}
      end
    end)
  end
end
