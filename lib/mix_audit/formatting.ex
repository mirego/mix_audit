defmodule MixAudit.Formatting do
  @default_format MixAudit.Formatting.Human
  @formats %{
    "human" => MixAudit.Formatting.Human,
    "json" => MixAudit.Formatting.JSON
  }

  def format(report, format) do
    @formats
    |> Map.get(format, @default_format)
    |> (& &1.format(report)).()
  end
end
