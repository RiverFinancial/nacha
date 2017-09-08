defmodule Nacha.Records.BatchHeader do
  @moduledoc """
  A struct containing data for a batch header record.
  """

  use Nacha.Record, keys: [
    {:record_type_code,     :number, 1,   5},
    {:service_class_code,   :string, 3},
    {:company_name,         :string, 16},
    {:discretionary_data,   :string, 20},
    {:company_id,           :string, 10},
    {:standard_entry_class, :string, 3},
    {:entry_description,    :string, 10},
    {:descriptive_date,     :date,   6},
    {:effective_date,       :date,   6},
    {:settlement_date,      :string, 3},
    {:originator_status,    :string, 1,   "1"},
    {:odfi_id,              :string, 8},
    {:batch_number,         :number, 7}]
end
