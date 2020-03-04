defmodule MixAudit.Dependency do
  @derive Jason.Encoder
  defstruct package: nil, version: nil, lockfile: nil
end
