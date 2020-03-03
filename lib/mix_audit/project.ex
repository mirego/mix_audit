defmodule MixAudit.Project do
  def dependencies(path) do
    Enum.flat_map(lockfiles(path), &map_lockfile_to_dependencies/1)
  end

  defp lockfiles(path) do
    Path.wildcard(Path.join(path, "mix.lock")) ++
      Path.wildcard(Path.join(path, "apps/**/mix.lock"))
  end

  defp map_lockfile_to_dependencies(lockfile) do
    {data, _} = Code.eval_file(lockfile)
    Enum.map(data, &map_dependency(&1, lockfile))
  end

  defp map_dependency(
         {package, {_provider, _name, version, _checksum, _tools, _, _origin}},
         lockfile
       ) do
    %MixAudit.Dependency{package: to_string(package), version: version, lockfile: lockfile}
  end

  defp map_dependency(
         {package, {_provider, _name, version, _checksum, _tools, _, _origin, _checksum_}},
         lockfile
       ) do
    %MixAudit.Dependency{package: to_string(package), version: version, lockfile: lockfile}
  end
end
