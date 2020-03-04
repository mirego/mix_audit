defmodule MixAudit.Formatting.Human do
  def format(report) do
    if report.pass do
      "No vulnerabilities found."
    else
      """
      #{map_vulnerabilities(report.vulnerabilities)}
      Vulnerabilities found!
      """
    end
  end

  defp map_vulnerabilities(vulnerabilities) do
    vulnerabilities
    |> Enum.map(&map_vulnerability/1)
    |> Enum.join("\n")
  end

  defp map_vulnerability(vulnerability) do
    """
    Name: #{vulnerability.dependency.package}
    Version: #{vulnerability.dependency.version}
    CVE: #{vulnerability.advisory.cve}
    URL: #{vulnerability.advisory.url}
    Title: #{String.trim(vulnerability.advisory.title)}
    Patched versions: #{Enum.join(vulnerability.advisory.patched_versions, ", ")}
    """
  end
end
