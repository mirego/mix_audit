defmodule MixAudit.RepoTest do
  use ExUnit.Case

  alias MixAudit.Repo

  doctest Repo

  test "advisories/0 returns a map of security advisories" do
    assert is_list(Repo.advisories())
  end

  test "read_advisories/0 returns a list without synchronizing" do
    assert is_list(Repo.read_advisories())
  end

  describe "synchronize/1" do
    test "returns an error tuple when the mirror directory is not writable" do
      # Reproduce the CI failure: the parent of the mirror directory is not
      # writable, so git cannot create the mirror and exits non-zero. This must
      # be surfaced as an error rather than silently ignored.
      parent = Path.join(System.tmp_dir!(), "mix_audit_readonly_#{System.unique_integer([:positive])}")
      File.mkdir!(parent)
      File.chmod!(parent, 0o555)

      on_exit(fn ->
        File.chmod(parent, 0o755)
        File.rm_rf(parent)
      end)

      repo_path = Path.join(parent, "mirror")

      # Skip when the permission restriction is not effective (e.g. running as
      # root, which ignores directory permission bits), since git would succeed.
      if writable?(repo_path) do
        IO.puts("Skipping: directory permissions are not enforced (running as root?)")
      else
        assert {:error, {:git, exit_status, output}} = Repo.synchronize(repo_path)
        assert is_integer(exit_status) and exit_status != 0
        assert is_binary(output)
      end
    end
  end

  defp writable?(path) do
    case File.mkdir(path) do
      :ok ->
        File.rmdir(path)
        true

      {:error, _} ->
        false
    end
  end
end
