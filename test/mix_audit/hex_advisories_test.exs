defmodule MixAudit.HexAdvisoriesTest do
  use ExUnit.Case

  alias MixAudit.HexAdvisories

  test "map_package_advisories/3 maps Hex advisory indexes to exact vulnerable versions" do
    releases = [
      %{version: "0.1.0", advisory_indexes: [0]},
      %{version: "0.2.0", advisory_indexes: [0, 1]},
      %{version: "1.0.0", advisory_indexes: []}
    ]

    advisories = [
      %{
        id: "GHSA-1234",
        severity: :SEVERITY_HIGH,
        html_url: "https://osv.dev/vulnerability/GHSA-1234",
        summary: "Vulnerable challenge handling"
      },
      %{
        id: "GHSA-5678",
        severity: "medium",
        api_url: "https://api.osv.dev/v1/vulns/GHSA-5678",
        summary: "Replay vulnerability"
      }
    ]

    assert [
             %MixAudit.Advisory{
               id: "GHSA-1234",
               package: "altcha",
               severity: "high",
               url: "https://osv.dev/vulnerability/GHSA-1234",
               title: "Vulnerable challenge handling",
               description: "Vulnerable challenge handling",
               vulnerable_version_ranges: ["= 0.1.0", "= 0.2.0"],
               first_patched_versions: ["1.0.0"]
             },
             %MixAudit.Advisory{
               id: "GHSA-5678",
               package: "altcha",
               severity: "medium",
               url: "https://api.osv.dev/v1/vulns/GHSA-5678",
               title: "Replay vulnerability",
               vulnerable_version_ranges: ["= 0.2.0"],
               first_patched_versions: ["1.0.0"]
             }
           ] = HexAdvisories.map_package_advisories("altcha", releases, advisories)
  end

  test "map_package_advisories/3 collapses aliased OSV records" do
    releases = [
      %{version: "1.0.0", advisory_indexes: [0]},
      %{version: "1.1.0", advisory_indexes: [0, 1]},
      %{version: "1.2.0", advisory_indexes: []}
    ]

    advisories = [
      %{
        id: "EEF-CVE-2026-39803",
        aliases: ["CVE-2026-39803", "GHSA-9q9q-324x-93r2"],
        severity: :SEVERITY_HIGH,
        summary: "EEF record"
      },
      %{
        id: "GHSA-9q9q-324x-93r2",
        aliases: ["CVE-2026-39803", "EEF-CVE-2026-39803"],
        severity: :SEVERITY_HIGH,
        summary: "GHSA record"
      }
    ]

    assert [
             %MixAudit.Advisory{
               id: "GHSA-9q9q-324x-93r2",
               package: "bandit",
               title: "GHSA record",
               vulnerable_version_ranges: ["= 1.0.0", "= 1.1.0"],
               first_patched_versions: ["1.2.0"]
             }
           ] = HexAdvisories.map_package_advisories("bandit", releases, advisories)
  end
end
