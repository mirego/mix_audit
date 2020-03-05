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

  defp is_vulnerability?(%MixAudit.Advisory{patched_versions: patched_versions, unaffected_versions: unaffected_versions}, %MixAudit.Dependency{version: version}) do
    patched_version = Enum.any?(patched_versions, &Version.match?(version, &1))
    unaffected_version = Enum.any?(unaffected_versions, &Version.match?(version, &1))

    !patched_version && !unaffected_version
  end

  defp map_vulnerability(advisory, dependency) do
    %MixAudit.Vulnerability{
      advisory: advisory,
      dependency: dependency
    }
  end
end
