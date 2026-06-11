defmodule MixAudit.DependencyUpdater do
  @moduledoc """
  Provides functionality to update project dependencies by invoking `mix deps.update` for specific packages.
  This module is used by `MixAudit.Fix` to attempt automatic remediation of vulnerable dependencies
  by updating them to non-vulnerable versions, if available.
  """

  @doc """
  Updates the given package in the project at the specified path by invoking `mix deps.update`.
  """
  def call(package, path) do
    # We deliberately shell out to `mix deps.update` rather than calling
    # Mix.Task.rerun/2 in-process. The in-process approach only works when
    # the target path matches the current Mix project, would silently misbehave
    # for the --path option, and is not covered by tests. A subprocess is
    # consistent, path-independent, and leaves no global Mix state side effects.
    case System.cmd("mix", ["deps.update", package], cd: path, stderr_to_stdout: true) do
      {_, 0} -> :ok
      {output, code} -> {:error, {code, output}}
    end
  end
end
