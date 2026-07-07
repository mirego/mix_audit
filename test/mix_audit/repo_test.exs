defmodule MixAudit.RepoTest do
  use ExUnit.Case
  doctest MixAudit.Repo

  @clone Path.join([System.user_home(), ".local", "share", "elixir-security-advisories-mirego"])

  test "advisories/0 returns a map of security advisories" do
    assert is_list(MixAudit.Repo.advisories())
  end

  test "force-syncs a dirty clone clean instead of aborting" do
    # Ensure the clone exists and is synced, then restore it whatever the test does.
    MixAudit.Repo.advisories()
    on_exit(fn -> System.cmd("git", ["checkout", "--", "README.md"], cd: @clone) end)

    # A dirty tracked file must not break the next sync: a plain `git pull --rebase` aborts
    # here ("cannot pull with rebase: You have unstaged changes") and leaves the tree dirty.
    File.write!(Path.join(@clone, "README.md"), "dirty\n")
    assert {_, 1} = System.cmd("git", ["diff", "--quiet"], cd: @clone)

    # fetch + reset --hard force-syncs regardless, leaving a clean tree.
    assert is_list(MixAudit.Repo.advisories())
    assert {_, 0} = System.cmd("git", ["diff", "--quiet"], cd: @clone)
  end
end
