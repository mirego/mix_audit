defmodule MixAudit.Repo do
  @url "https://github.com/dependabot/elixir-security-advisories.git"

  def advisories do
    synchronize()

    package_advisories_path()
    |> Path.wildcard()
    |> Enum.map(fn advisory_path ->
      {:ok, advisory_data} = YamlElixir.read_from_file(advisory_path)

      %MixAudit.Advisory{
        id: advisory_data["id"],
        package: advisory_data["package"],
        disclosure_date: advisory_data["disclosure_date"],
        cve: advisory_data["cve"],
        link: advisory_data["link"],
        title: advisory_data["title"],
        description: advisory_data["description"],
        patched_versions: advisory_data["patched_versions"] || [],
        unaffected_versions: advisory_data["unaffected_versions"] || []
      }
    end)
    |> Enum.group_by(& &1.package)
  end

  defp synchronize do
    local_path = path()

    if File.dir?(local_path) do
      previous_wd = File.cwd!()
      File.cd(local_path)
      System.cmd("git", ["pull", "--rebase", "--quiet", "origin", "master"])
      File.cd(previous_wd)
    else
      System.cmd("git", ["clone", "--quiet", @url, local_path])
    end
  end

  defp path do
    Path.join([System.get_env("HOME"), ".local", "share", "elixir-security-advisories"])
  end

  defp package_advisories_path do
    Path.join([path(), "packages", "**", "*.yml"])
  end
end
