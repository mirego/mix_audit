defmodule MixAudit.FixTest do
  use ExUnit.Case, async: true

  alias MixAudit.Advisory
  alias MixAudit.Dependency
  alias MixAudit.Fix
  alias MixAudit.Vulnerability

  describe "call/3 — no patched version available" do
    test "marks package as manual when advisory has no first_patched_versions" do
      result = Fix.call([vulnerability_fixture("plug", "1.9.0", [])], ".")

      assert result == %{
               fixed: [],
               manual: [%{package: "plug", reason: :no_patched_versions}],
               failed: []
             }
    end

    test "marks package as manual when all patches are major version bumps" do
      result = Fix.call([vulnerability_fixture("plug", "1.9.0", ["2.0.0"])], ".")

      assert result.manual == [%{package: "plug", reason: :requires_major_bump}]
    end

    test "ignores cross-major patches and still proceeds with the same-major one" do
      result =
        Fix.call([vulnerability_fixture("plug", "1.9.0", ["1.9.4", "2.0.0"])], ".",
          updater: stub_updater_success(),
          dependency_reader: stub_dependency_reader([dependency_fixture("plug", "1.9.4")])
        )

      assert [%{package: "plug", from: "1.9.0", to: "1.9.4"}] = result.fixed
    end

    test "marks package as manual when current version cannot be parsed" do
      result = Fix.call([vulnerability_fixture("plug", "not-semver", ["1.0.0"])], ".")

      assert result.manual == [%{package: "plug", reason: :malformed_version}]
    end
  end

  describe "call/3 — update succeeds" do
    test "marks as fixed when new version exactly equals the minimum patch" do
      result =
        Fix.call([vulnerability_fixture("plug", "1.9.0", ["1.9.4"])], ".",
          updater: stub_updater_success(),
          dependency_reader: stub_dependency_reader([dependency_fixture("plug", "1.9.4")])
        )

      assert result == %{
               fixed: [%{package: "plug", from: "1.9.0", to: "1.9.4"}],
               manual: [],
               failed: []
             }
    end

    test "marks as fixed when new version exceeds the minimum patch" do
      result =
        Fix.call([vulnerability_fixture("plug", "1.9.0", ["1.9.4"])], ".",
          updater: stub_updater_success(),
          dependency_reader: stub_dependency_reader([dependency_fixture("plug", "1.9.10")])
        )

      assert [%{package: "plug", from: "1.9.0", to: "1.9.10"}] = result.fixed
    end

    test "marks as manual when new version is still below the required minimum" do
      result =
        Fix.call([vulnerability_fixture("plug", "1.9.0", ["1.9.4"])], ".",
          updater: stub_updater_success(),
          dependency_reader: stub_dependency_reader([dependency_fixture("plug", "1.9.2")])
        )

      assert result.manual == [%{package: "plug", reason: :constraint_in_mix_exs}]
    end

    test "marks as manual when package is absent from lockfile after update" do
      result =
        Fix.call([vulnerability_fixture("plug", "1.9.0", ["1.9.4"])], ".",
          updater: stub_updater_success(),
          dependency_reader: stub_dependency_reader([])
        )

      assert result.manual == [%{package: "plug", reason: :package_removed}]
    end
  end

  describe "call/3 — updater fails" do
    test "marks as failed and preserves the error reason" do
      result =
        Fix.call([vulnerability_fixture("plug", "1.9.0", ["1.9.4"])], ".", updater: stub_updater_failure())

      assert result == %{
               fixed: [],
               manual: [],
               failed: [%{package: "plug", reason: {1, "mix deps.update failed"}}]
             }
    end
  end

  describe "call/3 — multiple advisories for the same package" do
    test "requires the version satisfying all advisories (max of per-advisory minimums)" do
      dep = dependency_fixture("plug", "1.9.0")

      vulns = [
        %Vulnerability{
          dependency: dep,
          advisory: %Advisory{
            id: "CVE-001",
            package: "plug",
            first_patched_versions: ["1.9.3"]
          }
        },
        %Vulnerability{
          dependency: dep,
          advisory: %Advisory{
            id: "CVE-002",
            package: "plug",
            first_patched_versions: ["1.9.4"]
          }
        }
      ]

      # 1.9.3 satisfies CVE-001 but not CVE-002 (>= 1.9.4 is required for CVE-002)
      result_insufficient =
        Fix.call(vulns, ".",
          updater: stub_updater_success(),
          dependency_reader: stub_dependency_reader([dependency_fixture("plug", "1.9.3")])
        )

      assert result_insufficient.manual == [%{package: "plug", reason: :constraint_in_mix_exs}]

      # 1.9.4 satisfies both CVEs
      result_sufficient =
        Fix.call(vulns, ".",
          updater: stub_updater_success(),
          dependency_reader: stub_dependency_reader([dependency_fixture("plug", "1.9.4")])
        )

      assert [%{package: "plug", from: "1.9.0", to: "1.9.4"}] = result_sufficient.fixed
    end

    test "halts when any advisory has an empty first_patched_versions" do
      dep = dependency_fixture("plug", "1.9.0")

      vulns = [
        %Vulnerability{
          dependency: dep,
          advisory: %Advisory{id: "CVE-001", package: "plug", first_patched_versions: ["1.9.3"]}
        },
        %Vulnerability{
          dependency: dep,
          advisory: %Advisory{id: "CVE-002", package: "plug", first_patched_versions: []}
        }
      ]

      result = Fix.call(vulns, ".")

      assert result.manual == [%{package: "plug", reason: :no_patched_versions}]
    end

    test "halts when any advisory only provides cross-major patches" do
      dep = dependency_fixture("plug", "1.9.0")

      vulns = [
        %Vulnerability{
          dependency: dep,
          advisory: %Advisory{id: "CVE-001", package: "plug", first_patched_versions: ["1.9.3"]}
        },
        %Vulnerability{
          dependency: dep,
          advisory: %Advisory{id: "CVE-002", package: "plug", first_patched_versions: ["2.0.0"]}
        }
      ]

      result = Fix.call(vulns, ".")

      assert result.manual == [%{package: "plug", reason: :requires_major_bump}]
    end
  end

  describe "call/3 — multiple packages" do
    test "processes each package independently and accumulates results" do
      vulns = [
        vulnerability_fixture("plug", "1.9.0", ["1.9.4"]),
        vulnerability_fixture("jason", "1.0.0", ["2.0.0"])
      ]

      result =
        Fix.call(vulns, ".",
          updater: stub_updater_success(),
          dependency_reader: stub_dependency_reader([dependency_fixture("plug", "1.9.4"), dependency_fixture("jason", "1.0.0")])
        )

      assert [%{package: "plug"}] = result.fixed
      assert [%{package: "jason", reason: :requires_major_bump}] = result.manual
      assert result.failed == []
    end

    test "one package failing does not affect the others" do
      vulns = [
        vulnerability_fixture("plug", "1.9.0", ["1.9.4"]),
        vulnerability_fixture("phoenix", "1.6.0", ["1.6.14"])
      ]

      selective_stub_updater_failure = fn
        "plug", _path -> {:error, {1, "failed"}}
        _pkg, _path -> :ok
      end

      result =
        Fix.call(vulns, ".",
          updater: selective_stub_updater_failure,
          dependency_reader: stub_dependency_reader([dependency_fixture("plug", "1.9.0"), dependency_fixture("phoenix", "1.6.14")])
        )

      assert [%{package: "plug", reason: {1, "failed"}}] = result.failed
      assert [%{package: "phoenix", from: "1.6.0", to: "1.6.14"}] = result.fixed
    end
  end

  defp dependency_fixture(package, version) do
    %Dependency{package: package, version: version, lockfile: "mix.lock"}
  end

  defp vulnerability_fixture(package, version, patched_versions) do
    %Vulnerability{
      dependency: dependency_fixture(package, version),
      advisory: %Advisory{id: "TEST-123", package: package, first_patched_versions: patched_versions}
    }
  end

  defp stub_updater_success, do: fn _pkg, _path -> :ok end
  defp stub_updater_failure, do: fn _pkg, _path -> {:error, {1, "mix deps.update failed"}} end
  defp stub_dependency_reader(deps), do: fn _path -> deps end
end
