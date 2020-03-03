defmodule MixAudit.Advisory do
  defstruct id: nil,
            package: nil,
            disclosure_date: nil,
            cve: nil,
            link: nil,
            title: nil,
            description: nil,
            patched_versions: [],
            unaffected_versions: []
end
