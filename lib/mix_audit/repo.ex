defmodule MixAudit.Repo do
  @url "https://github.com/dependabot/elixir-security-advisories.git"

  def advisories do
    synchronize()

    package_advisories_path()
    |> Path.wildcard()
    |> Enum.map(&map_advisory/1)
  end

  defp synchronize do
    repo_path = path()

    if File.dir?(repo_path) do
      previous_path = File.cwd!()
      File.cd(repo_path)

      System.cmd("git", ["pull", "--rebase", "--quiet", "origin", "master"])

      File.cd(previous_path)
    else
      System.cmd("git", ["clone", "--quiet", @url, repo_path])
    end
  end

  defp path do
    Path.join([System.get_env("HOME"), ".local", "share", "elixir-security-advisories"])
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
      cve: advisory_data["cve"],
      url: advisory_data["link"],
      title: advisory_data["title"],
      description: advisory_data["description"],
      patched_versions: advisory_data["patched_versions"] || [],
      unaffected_versions: advisory_data["unaffected_versions"] || []
    }
  end
end
