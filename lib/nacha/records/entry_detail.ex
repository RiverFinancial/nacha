defmodule Nacha.Records.EntryDetail do
  @moduledoc """
  A struct containing data for an individual entry detail record,
  which represents a single transfer.
  """

  alias Nacha.Utils

  use Nacha.Record,
    fields: [
      {:standard_entry_class, :string, 0},
      {:record_type_code, :number, 1, 6},
      {:transaction_code, :string, 2},
      {:rdfi_id, :string, 8},
      {:check_digit, :number, 1},
      {:account_number, :string, 17},
      {:amount, :number, 10},
      {:individual_id, :string, 15},
      {:individual_name, :string, 22},
      {:discretionary_data, :string, 2},
      {:addenda_indicator, :number, 1, 0},
      {:trace_id, :number, 8},
      {:trace_number, :number, 7}
    ]

  # override default validation to add check digit validation
  def validate(
        %{
          rdfi_id: rdfi_id,
          check_digit: check_digit
        } = entry_detail
      ) do
    case Utils.get_check_digit_from_routing_number(rdfi_id) do
      ^check_digit ->
        entry_detail

      _ ->
        Map.update!(
          entry_detail,
          :errors,
          &[{:check_digit, "incorrect check digit"} | &1]
        )
    end
    |> super()
  end
end
