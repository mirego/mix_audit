defmodule MixAudit.Formatting.JSON do
  def format(report) do
    Jason.encode!(report)
  end
end
