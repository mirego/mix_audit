defmodule MixAudit.Report do
  @derive Jason.Encoder
  defstruct vulnerabilities: [], pass: false
end
