defmodule Nacha.Records.Addendum do
  @moduledoc """
  A struct containing data for an entry detail addendum record.
  """

  @required [
    :record_type_code,
    :addendum_type_code,
    :addendum_sequence_number,
    :entry_detail_sequence_number
  ]

  use Nacha.Record,
    fields: [
      {:record_type_code, :number, 1, 7},
      {:addendum_type_code, :number, 2, 5},
      {:payment_related_data, :string, 80},
      {:addendum_sequence_number, :number, 4, 1},
      {:entry_detail_sequence_number, :number, 7}
    ]
end
