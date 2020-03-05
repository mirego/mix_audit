defmodule MixAudit.RepoTest do
  use ExUnit.Case
  doctest MixAudit.Repo

  test "advisories/0 returns a map of security advisories" do
    assert is_map(MixAudit.Repo.advisories())
  end
end
