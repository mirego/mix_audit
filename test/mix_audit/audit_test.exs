defmodule MixAudit.AuditTest do
  use ExUnit.Case
  doctest MixAudit.Audit

  alias MixAudit.Audit

  test "report/2 includes vulnerabilities based on vulnerable version ranges" do
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
          id: "ABC-123",
          description: "Bar",
          title: "Foo",
          package: "foo",
          disclosure_date: "1970-01-01",
          url: "https://example.com",
          vulnerable_version_ranges: ["~> 0.7.2"],
          severity: "high"
        }
      ]
    }

    report = Audit.report(dependencies, advisories)
    [first_vulnerability | _] = report.vulnerabilities

    refute report.pass
    assert first_vulnerability.advisory.id == "ABC-123"
    assert first_vulnerability.advisory.severity == "high"
    assert first_vulnerability.dependency.package == "foo"
    assert first_vulnerability.dependency.version == "0.7.4"
  end

  test "report/2 includes vulnerabilities based on complex vulnerable version ranges" do
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
          id: "ABC-123",
          description: "Bar",
          title: "Foo",
          package: "foo",
          disclosure_date: "1970-01-01",
          url: "https://example.com",
          vulnerable_version_ranges: ["> 0.7.2, < 0.7.9"],
          severity: "high"
        }
      ]
    }

    report = Audit.report(dependencies, advisories)
    [first_vulnerability | _] = report.vulnerabilities

    refute report.pass
    assert first_vulnerability.advisory.id == "ABC-123"
    assert first_vulnerability.advisory.severity == "high"
    assert first_vulnerability.dependency.package == "foo"
    assert first_vulnerability.dependency.version == "0.7.4"
  end

  test "report/2 does not include vulnerabilities based on complex vulnerable version ranges" do
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
          id: "ABC-123",
          description: "Bar",
          title: "Foo",
          package: "foo",
          disclosure_date: "1970-01-01",
          url: "https://example.com",
          vulnerable_version_ranges: ["> 0.7.5, < 0.7.9", "= 0.7.3"],
          severity: "high"
        }
      ]
    }

    report = Audit.report(dependencies, advisories)

    assert report.pass
    assert report.vulnerabilities == []
  end
end
