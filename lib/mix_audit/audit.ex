defmodule MixAudit.Audit do
  def report(dependencies, advisories) do
    vulnerabilities =
      Enum.reduce(dependencies, [], fn dependency, memo ->
        advisories
        |> Map.get(dependency.package, [])
        |> Enum.filter(&is_vulnerability?(&1, dependency))
        |> Enum.map(&map_vulnerability(&1, dependency))
        |> (&(memo ++ &1)).()
      end)

    %MixAudit.Report{
      vulnerabilities: vulnerabilities,
      pass: Enum.empty?(vulnerabilities)
    }
  end

  defp is_vulnerability?(%MixAudit.Advisory{vulnerable_version_ranges: vulnerable_version_ranges}, %MixAudit.Dependency{version: version}) do
    Enum.any?(vulnerable_version_ranges, fn version_range ->
      version_range
      |> map_ranges_to_requirements()
      |> Enum.all?(&Version.match?(version, &1))
    end)
  end

  defp map_vulnerability(advisory, dependency) do
    %MixAudit.Vulnerability{
      advisory: advisory,
      dependency: dependency
    }
  end

  defp map_ranges_to_requirements(version_ranges) do
    version_ranges
    |> String.split(",")
    |> Enum.map(&String.trim(&1))
    |> Enum.map(&String.replace(&1, ~r/^=[^=]/, "=="))
  end
end
