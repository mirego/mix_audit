defmodule MixAudit.Formatting.HumanTest do
  use ExUnit.Case

  alias MixAudit.Formatting.Human

  test "format/1 with vulnerabilities" do
    report = %MixAudit.Report{
      pass: false,
      vulnerabilities: [
        %MixAudit.Vulnerability{
          advisory: %MixAudit.Advisory{
            id: "ABC-123",
            description: "Bar",
            title: "Foo",
            package: "foo",
            disclosure_date: "1970-01-01",
            url: "https://example.com",
            vulnerable_version_ranges: ["~> 0.7.2"],
            severity: "high"
          },
          dependency: %MixAudit.Dependency{
            package: "foo",
            version: "0.7.4",
            lockfile: "mix.lock"
          }
        }
      ]
    }

    report = Human.format(report)
    assert report =~ "Vulnerabilities found"
    assert report =~ ~r/Name:.*foo/
    assert report =~ ~r/Version:.*0.7.4/
    assert report =~ ~r/Lockfile:.*mix.lock/
    assert report =~ ~r/URL:.*https:\/\/example.com/
    assert report =~ ~r/Title:.*Foo/
    assert report =~ ~r/Vulnerable versions:.*~> 0.7.2/
    assert report =~ ~r/First patched versions:.*NONE/
    assert report =~ ~r/Severity:.*high/
  end

  test "format/1 without vulnerabilities" do
    report = %MixAudit.Report{
      pass: true,
      vulnerabilities: []
    }

    report = Human.format(report)
    assert report =~ "No vulnerabilities found."
  end
end
