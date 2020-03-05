defmodule MixAudit do
  @version Mix.Project.config()[:version]

  def version, do: @version
end
