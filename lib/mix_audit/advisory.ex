defmodule MixAudit.Advisory do
  @derive Jason.Encoder
  defstruct id: nil,
            package: nil,
            disclosure_date: nil,
            url: nil,
            title: nil,
            description: nil,
            vulnerable_version_ranges: [],
            first_patched_versions: []
end
