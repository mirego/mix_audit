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
      pass: length(vulnerabilities) == 0
    }
  end

  def is_vulnerability?(
        %MixAudit.Advisory{
          patched_versions: patched_versions,
          unaffected_versions: unaffected_versions
        },
        %MixAudit.Dependency{version: version}
      ) do
    patched_version =
      Enum.any?(patched_versions, fn version_requirement ->
        Version.match?(version, version_requirement)
      end)

    unaffected_version =
      Enum.any?(unaffected_versions, fn version_requirement ->
        Version.match?(version, version_requirement)
      end)

    !patched_version && !unaffected_version
  end

  defp map_vulnerability(advisory, dependency) do
    %MixAudit.Vulnerability{
      advisory: advisory,
      dependency: dependency
    }
  end
end
