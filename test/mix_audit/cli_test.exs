defmodule MixAudit.CLITest do
  use ExUnit.Case

  alias MixAudit.Repo

  @test_dir "test/support"

  describe "run/1" do
    test "works without any option" do
      {output, exit_code} = System.cmd("mix", ["deps.audit"])

      assert output == "No vulnerabilities found.\n"
      assert exit_code == 0
    end

    test "works with --path option" do
      working_dir = File.cwd!()

      {output, exit_code} = System.cmd("mix", ["deps.audit", "--path", "#{@test_dir}/apps/bar"])

      assert output == """
             Name: absinthe\nVersion: 1.4.16
             Lockfile: #{working_dir}/#{@test_dir}/apps/bar/mix.lock
             URL: https://github.com/advisories/GHSA-9mhv-8h52-q7q2
             Title: Absinthe: Quadratic fragment-name uniqueness check
             Severity: high
             Vulnerable versions: >= 1.2.0, < 1.10.2
             First patched versions: 1.10.2

             Vulnerabilities found!
             """

      assert exit_code == 1

      {output, exit_code} = System.cmd("mix", ["deps.audit", "--path", "#{@test_dir}/apps/foo"])
      assert output == "No vulnerabilities found.\n"
      assert exit_code == 0

      {output, exit_code} = System.cmd("mix", ["deps.audit", "--path", "#{@test_dir}"])

      assert output == """
             Name: plug
             Version: 1.9.0
             Lockfile: #{working_dir}/#{@test_dir}/mix.lock
             URL: https://github.com/advisories/GHSA-468c-vq7p-gh64
             Title: Plug: Unbounded buffer accumulation in multipart header parsing causes denial of service
             Severity: high
             Vulnerable versions: >= 1.19.0, < 1.19.2, >= 1.18.0, < 1.18.2, >= 1.17.0, < 1.17.1, >= 1.16.0, < 1.16.3, >= 1.4.0, < 1.15.4
             First patched versions: 1.19.2, 1.18.2, 1.17.1, 1.16.3, 1.15.4

             Name: absinthe
             Version: 1.4.16
             Lockfile: #{working_dir}/#{@test_dir}/apps/bar/mix.lock
             URL: https://github.com/advisories/GHSA-9mhv-8h52-q7q2
             Title: Absinthe: Quadratic fragment-name uniqueness check
             Severity: high
             Vulnerable versions: >= 1.2.0, < 1.10.2
             First patched versions: 1.10.2

             Vulnerabilities found!
             """

      assert exit_code == 1
    end

    test "works with --ignore-unfixed option" do
      working_dir = File.cwd!()

      {output, exit_code} = System.cmd("mix", ["deps.audit", "--path", "#{@test_dir}/apps/bar", "--ignore-unfixed"])

      assert output == """
             Name: absinthe\nVersion: 1.4.16
             Lockfile: #{working_dir}/#{@test_dir}/apps/bar/mix.lock
             URL: https://github.com/advisories/GHSA-9mhv-8h52-q7q2
             Title: Absinthe: Quadratic fragment-name uniqueness check
             Severity: high
             Vulnerable versions: >= 1.2.0, < 1.10.2
             First patched versions: 1.10.2

             Vulnerabilities found!
             """

      assert exit_code == 1

      {output, exit_code} = System.cmd("mix", ["deps.audit", "--path", "#{@test_dir}/apps/foo", "--ignore-unfixed"])
      assert output == "No vulnerabilities found.\n"
      assert exit_code == 0

      {output, exit_code} = System.cmd("mix", ["deps.audit", "--path", "#{@test_dir}", "--ignore-unfixed"])

      assert output == """
             Name: plug
             Version: 1.9.0
             Lockfile: #{working_dir}/#{@test_dir}/mix.lock
             URL: https://github.com/advisories/GHSA-468c-vq7p-gh64
             Title: Plug: Unbounded buffer accumulation in multipart header parsing causes denial of service
             Severity: high
             Vulnerable versions: >= 1.19.0, < 1.19.2, >= 1.18.0, < 1.18.2, >= 1.17.0, < 1.17.1, >= 1.16.0, < 1.16.3, >= 1.4.0, < 1.15.4
             First patched versions: 1.19.2, 1.18.2, 1.17.1, 1.16.3, 1.15.4

             Name: absinthe
             Version: 1.4.16
             Lockfile: #{working_dir}/#{@test_dir}/apps/bar/mix.lock
             URL: https://github.com/advisories/GHSA-9mhv-8h52-q7q2
             Title: Absinthe: Quadratic fragment-name uniqueness check
             Severity: high
             Vulnerable versions: >= 1.2.0, < 1.10.2
             First patched versions: 1.10.2

             Vulnerabilities found!
             """

      assert exit_code == 1

      unfixed_advisory = Enum.find(Repo.advisories(), &(&1.first_patched_versions in [[], nil, [nil]]))

      if not is_nil(unfixed_advisory) do
        unfixed_dir = @test_dir <> "/unfixed"

        if File.dir?(unfixed_dir) do
          File.rm_rf!(unfixed_dir)
        end

        File.mkdir_p!(unfixed_dir)

        vulnerable_version =
          unfixed_advisory.vulnerable_version_ranges
          |> List.first()
          |> String.split("<= ")
          |> List.last()

        lock_content = """
        %{
          "#{unfixed_advisory.package}": {:hex, :#{unfixed_advisory.package}, "#{vulnerable_version}", "ae2718484892448a24470e6aa341bc847c3277bfb8d4e9289f7474d752c09c7f", [:rebar3], [], "hexpm", "4738382e36a0a9a2b6e25d67c960e40e1a2c95560b9f936d8e29de8cd858480f"},
        }
        """

        File.write!(unfixed_dir <> "/mix.lock", lock_content)

        {output, exit_code} = System.cmd("mix", ["deps.audit", "--path", unfixed_dir, "--ignore-unfixed"])
        assert output == "No vulnerabilities found.\n"
        assert exit_code == 0

        {output, exit_code} = System.cmd("mix", ["deps.audit", "--path", unfixed_dir])

        assert output == """
               Name: #{unfixed_advisory.package}
               Version: #{vulnerable_version}
               Lockfile: #{working_dir}/#{unfixed_dir}/mix.lock
               URL: #{unfixed_advisory.url}
               Title: #{unfixed_advisory.title}
               Severity: #{unfixed_advisory.severity}
               Vulnerable versions: #{Enum.join(unfixed_advisory.vulnerable_version_ranges, ", ")}
               First patched versions: \n\nVulnerabilities found!
               """

        assert exit_code == 1
      end
    end
  end
end
