defmodule MixAudit.CLI do
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        switches: [
          ignore_advisory_ids: :string,
          ignore_package_names: :string,
          ignore_file: :string,
          version: :boolean,
          help: :boolean,
          format: :string,
          path: :string
        ]
      )

    cond do
      opts[:version] ->
        MixAudit.CLI.Version.run(opts)

      opts[:help] ->
        MixAudit.CLI.Help.run(opts)

      true ->
        MixAudit.CLI.Audit.run(opts)
    end
  end
end
