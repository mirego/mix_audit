defmodule MixAudit.Advisory do
  @derive Jason.Encoder
  defstruct id: nil,
            package: nil,
            disclosure_date: nil,
            cve: nil,
            url: nil,
            title: nil,
            description: nil,
            patched_versions: [],
            unaffected_versions: []
end
