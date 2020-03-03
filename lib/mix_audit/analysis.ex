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

  def is_vulnerability?(_advisory, _dependency) do
    # TODO: This is temporary for now :)
    true
  end

  defp map_vulnerability(advisory, dependency) do
    %MixAudit.Vulnerability{
      advisory: advisory,
      dependency: dependency
    }
  end
end
