defmodule MixAudit.AuditTest do
  use ExUnit.Case
  doctest MixAudit.Audit

  test "report/2 includes vulnerabilities based on patched versions" do
    dependencies = [
      %MixAudit.Dependency{
        package: "foo",
        version: "0.7.4",
        lockfile: "mix.lock"
      }
    ]

    advisories = %{
      "foo" => [
        %MixAudit.Advisory{
          cve: "1",
          description: "Bar",
          title: "Foo",
          package: "foo",
          disclosure_date: "1970-01-01",
          url: "https://example.com",
          patched_versions: [
            "> 1.0.0"
          ],
          unaffected_versions: []
        }
      ]
    }

    report = MixAudit.Audit.report(dependencies, advisories)
    [first_vulnerability | _] = report.vulnerabilities

    refute report.pass
    assert first_vulnerability.advisory.cve == "1"
    assert first_vulnerability.dependency.package == "foo"
    assert first_vulnerability.dependency.version == "0.7.4"
  end

  test "report/2 excludes vulnerabilities based on unaffected versions" do
    dependencies = [
      %MixAudit.Dependency{
        package: "foo",
        version: "0.7.4",
        lockfile: "mix.lock"
      }
    ]

    advisories = %{
      "foo" => [
        %MixAudit.Advisory{
          cve: "1",
          description: "Bar",
          title: "Foo",
          package: "foo",
          disclosure_date: "1970-01-01",
          url: "https://example.com",
          patched_versions: [
            "> 1.0.0"
          ],
          unaffected_versions: [
            "0.7.4"
          ]
        }
      ]
    }

    report = MixAudit.Audit.report(dependencies, advisories)

    assert report.pass
  end
end
