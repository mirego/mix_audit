defmodule MixAudit.CLI do
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        switches: [
          ignore_advisory_ids: :string,
          ignore_package_names: :string,
          version: :boolean,
          help: :boolean,
          format: :string,
          path: :string
        ]
      )

    if opts[:version] do
      MixAudit.CLI.Version.run(opts)
    end

    if opts[:help] do
      MixAudit.CLI.Help.run(opts)
    end

    MixAudit.CLI.Audit.run(opts)
  end
end
