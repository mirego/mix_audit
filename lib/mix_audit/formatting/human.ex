defmodule MixAudit.Formatting.Human do
  def format(report) do
    if report.pass do
      colorized_text("No vulnerabilities found.", :green)
    else
      """
      #{map_vulnerabilities(report.vulnerabilities)}
      #{colorized_text("Vulnerabilities found!", :red)}
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
    #{colorized_text("Name:", :red)} #{vulnerability.dependency.package}
    #{colorized_text("Version:", :red)} #{vulnerability.dependency.version}
    #{colorized_text("Lockfile:", :red)} #{vulnerability.dependency.lockfile}
    #{colorized_text("CVE:", :red)} #{vulnerability.advisory.cve}
    #{colorized_text("URL:", :red)} #{vulnerability.advisory.url}
    #{colorized_text("Title:", :red)} #{String.trim(vulnerability.advisory.title)}
    #{colorized_text("Patched versions:", :red)} #{patched_versions(vulnerability.advisory.patched_versions)}
    """
  end

  defp colorized_text(string, color) do
    [color, string, :reset]
    |> IO.ANSI.format()
    |> IO.chardata_to_string()
  end

  defp patched_versions([]), do: "NONE"
  defp patched_versions(versions), do: Enum.join(versions, ", ")
end
