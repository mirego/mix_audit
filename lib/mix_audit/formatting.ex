defmodule MixAudit.Formatting do
  @formats %{
    "human" => MixAudit.Formatting.Human,
    "json" => MixAudit.Formatting.JSON
  }

  def format(report, format) do
    @formats
    |> Map.get(format, @formats["human"])
    |> (& &1.format(report)).()
  end
end
