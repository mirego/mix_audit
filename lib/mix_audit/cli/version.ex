defmodule MixAudit.CLI.Version do
  def run(_opts) do
    IO.puts(MixAudit.version())
    System.stop(0)

    true
  end
end
