defmodule MixAudit.CLITest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias MixAudit.CLI

  test "--version prints the version without running the audit" do
    output =
      capture_io(fn ->
        CLI.run(["--version"])
      end)

    assert String.trim(output) == MixAudit.version()
  end

  test "--help prints usage without running the audit" do
    output =
      capture_io(fn ->
        CLI.run(["--help"])
      end)

    assert output =~ "Usage: mix deps.audit"
    assert output =~ "--path"
  end
end