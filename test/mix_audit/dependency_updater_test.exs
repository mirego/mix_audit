defmodule MixAudit.DependencyUpdaterTest do
  use ExUnit.Case

  alias MixAudit.DependencyUpdater

  describe "call/2" do
    test "returns an error tuple when the path does not exist" do
      result = DependencyUpdater.call("plug", "/nonexistent/mix_audit_test_path")

      assert {:error, {_code, _output}} = result
    end

    test "returns an error tuple when the path has no mix project" do
      # System.tmp_dir! is a real directory but has no mix.exs, so mix will fail.
      result = DependencyUpdater.call("plug", System.tmp_dir!())

      assert {:error, {_code, _output}} = result
    end

    test "error tuple contains a non-zero exit code and string output" do
      {:error, {code, output}} = DependencyUpdater.call("plug", "/nonexistent/path")

      assert is_integer(code)
      assert code > 0
      assert is_binary(output)
    end
  end
end
