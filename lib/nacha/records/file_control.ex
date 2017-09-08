defmodule Nacha.Records.FileControl do
  @moduledoc """
  A struct containing data for a file control record.
  """

  use Nacha.Record, keys: [
    {:record_type_code, :number, 1,   9},
    {:batch_count,      :number, 6},
    {:block_count,      :number, 6},
    {:entry_count,      :number, 8},
    {:entry_hash,       :number, 10},
    {:total_debits,     :number, 12},
    {:total_credits,    :number, 12},
    {:reserved,         :string, 39}]
end
