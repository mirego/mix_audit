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
    Enum.map_join(vulnerabilities, "\n", &map_vulnerability/1)
  end

  defp map_vulnerability(vulnerability) do
    """
    #{colorized_text("Name:", :red)} #{vulnerability.dependency.package}
    #{colorized_text("Version:", :red)} #{vulnerability.dependency.version}
    #{colorized_text("Lockfile:", :red)} #{vulnerability.dependency.lockfile}
    #{colorized_text("URL:", :red)} #{vulnerability.advisory.url}
    #{colorized_text("Title:", :red)} #{String.trim(vulnerability.advisory.title)}
    #{colorized_text("Vulnerable versions:", :red)} #{versions(vulnerability.advisory.vulnerable_version_ranges)}
    #{colorized_text("First patched versions:", :red)} #{versions(vulnerability.advisory.first_patched_versions)}
    """
  end

  defp colorized_text(string, color) do
    [color, string, :reset]
    |> IO.ANSI.format()
    |> IO.chardata_to_string()
  end

  defp versions([]), do: "NONE"
  defp versions(versions), do: Enum.join(versions, ", ")
end
