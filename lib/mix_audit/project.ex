defmodule MixAudit.Project do
  def dependencies(path) do
    Enum.flat_map(lockfiles(path), &map_lockfile_to_dependencies/1)
  end

  defp lockfiles(path) do
    Path.wildcard(Path.join(path, "mix.lock")) ++ Path.wildcard(Path.join(path, "apps/**/mix.lock"))
  end

  defp map_lockfile_to_dependencies(lockfile) do
    lockfile
    |> read_lockfile()
    |> Map.values()
    |> Enum.map(&map_dependency(&1, lockfile))
    |> Enum.reject(&is_nil/1)
  end

  defp read_lockfile(lockfile) do
    opts = [file: lockfile, warn_on_unnecessary_quotes: false]

    with {:ok, contents} <- File.read(lockfile),
         assert_no_merge_conflicts_in_lockfile(lockfile, contents),
         {:ok, quoted} <- Code.string_to_quoted(contents, opts),
         {%{} = lock, _} <- Code.eval_quoted(quoted, [], opts) do
      lock
    else
      _ -> %{}
    end
  end

  defp map_dependency({:hex, package, version, _, _, _, _}, lockfile) do
    do_map_dependency(package, version, lockfile)
  end

  defp map_dependency({:hex, package, version, _, _, _, _, _}, lockfile) do
    do_map_dependency(package, version, lockfile)
  end

  defp map_dependency(_, _), do: nil

  defp do_map_dependency(package, version, lockfile) do
    %MixAudit.Dependency{package: to_string(package), version: version, lockfile: lockfile}
  end

  defp assert_no_merge_conflicts_in_lockfile(lockfile, info) do
    if String.contains?(info, ~w(<<<<<<< ======= >>>>>>>)) do
      Mix.raise("Your #{lockfile} contains merge conflicts. Please resolve the conflicts and run the command again")
    end
  end
end
