defmodule MixAudit.ProjectTest do
  use ExUnit.Case
  doctest MixAudit.Project

  test "dependencies/1 extracts dependencies from a project path" do
    dependencies =
      "test/support"
      |> MixAudit.Project.dependencies()
      |> Enum.sort_by(& &1.package)

    assert dependencies == [
             %MixAudit.Dependency{
               lockfile: "test/support/apps/bar/mix.lock",
               package: "absinthe",
               version: "1.4.16"
             },
             %MixAudit.Dependency{
               lockfile: "test/support/mix.lock",
               package: "plug",
               version: "1.9.0"
             },
             %MixAudit.Dependency{
               lockfile: "test/support/apps/foo/mix.lock",
               package: "telemetry",
               version: "0.4.1"
             }
           ]
  end

  @tag :tmp_dir
  test "dependencies/1 reads the lockfiles of a path with glob characters", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "project[1]{a}")
    File.cp_r!("test/support", path)

    packages =
      path
      |> MixAudit.Project.dependencies()
      |> Enum.map(& &1.package)
      |> Enum.sort()

    assert packages == ["absinthe", "plug", "telemetry"]
  end

  test "dependencies/1 returns an empty list for unknown path" do
    assert MixAudit.Project.dependencies("test/unknown") == []
  end
end
