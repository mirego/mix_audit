defmodule MixAudit.CLI.Version do
  def run(_opts) do
    IO.puts(MixAudit.version())
    System.halt(0)
  end
end
