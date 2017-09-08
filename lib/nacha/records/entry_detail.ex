defmodule Nacha.Records.EntryDetail do
  @moduledoc """
  A struct containing data for an individual entry detail record,
  which represents a single transfer.
  """

  use Nacha.Record, keys: [
    {:record_type_code,   :number, 1,   6},
    {:transaction_code,   :string, 2},
    {:rdfi_id,            :number, 8},
    {:check_digit,        :number, 1},
    {:account_number,     :string, 17},
    {:amount,             :number, 10},
    {:individual_id,      :string, 15},
    {:individual_name,    :string, 22},
    {:discretionary_data, :string, 2},
    {:addenda_indicator,  :number, 1,   0},
    {:trace_number,       :string, 15}]
end
