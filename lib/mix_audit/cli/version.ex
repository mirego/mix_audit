defmodule MixAudit.CLI.Version do
  def run(_opts) do
    IO.puts(MixAudit.version())
  end
end
