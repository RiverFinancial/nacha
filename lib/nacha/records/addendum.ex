defmodule Nacha.Records.Addendum do
  @moduledoc """
  A struct containing data for an entry detail addendum record.
  """
  alias Nacha.Records.Addendum

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

  defmodule NotificationOfChange do
    @type t :: %__MODULE__{
            reason_code: String.t(),
            original_entry_trace_number: String.t(),
            original_rdfi_id: integer(),
            corrected_data: String.t(),
            addendum_sequence_number: integer(),
            entry_detail_sequence_number: integer()
          }

    defstruct [
      :reason_code,
      :original_entry_trace_number,
      :original_rdfi_id,
      :corrected_data,
      :addendum_sequence_number,
      :entry_detail_sequence_number
    ]
  end

  defmodule Return do
    @type t :: %__MODULE__{
            reason_code: String.t(),
            original_entry_trace_number: String.t(),
            date_of_death: Date.t() | nil,
            original_rdfi_id: integer(),
            addenda_information: String.t(),
            addendum_sequence_number: integer(),
            entry_detail_sequence_number: integer()
          }

    defstruct [
      :reason_code,
      :original_entry_trace_number,
      :date_of_death,
      :original_rdfi_id,
      :addenda_information,
      :addendum_sequence_number,
      :entry_detail_sequence_number
    ]
  end

  # TODO remove Base struct and implement all other addendum type
  defmodule Basic do
    @type t :: %__MODULE__{
            record_type_code: integer(),
            addendum_type_code: integer(),
            payment_related_data: String.t(),
            addendum_sequence_number: integer(),
            entry_detail_sequence_number: integer()
          }

    defstruct [
      :record_type_code,
      :addendum_type_code,
      :payment_related_data,
      :addendum_sequence_number,
      :entry_detail_sequence_number
    ]
  end

  @spec to_detail(t()) :: NotificationOfChange.t() | Return.t() | Basic.t()

  def to_detail(%Addendum{
        addendum_type_code: 98,
        payment_related_data: <<
          reason_code::binary-size(3),
          original_entry_trace_number::binary-size(15),
          _::binary-size(6),
          original_rdfi_id::binary-size(8),
          corrected_data::binary-size(29),
          _::binary
        >>,
        addendum_sequence_number: addendum_sequence_number,
        entry_detail_sequence_number: entry_detail_sequence_number
      }) do
    %NotificationOfChange{
      reason_code: reason_code,
      original_entry_trace_number: original_entry_trace_number,
      original_rdfi_id: original_rdfi_id,
      corrected_data: corrected_data,
      addendum_sequence_number: addendum_sequence_number,
      entry_detail_sequence_number: entry_detail_sequence_number
    }
  end

  def to_detail(%Addendum{
        addendum_type_code: 99,
        payment_related_data: <<
          reason_code::binary-size(3),
          original_entry_trace_number::binary-size(15),
          date_of_death::binary-size(6),
          original_rdfi_id::binary-size(8),
          addenda_information::binary
        >>,
        addendum_sequence_number: addendum_sequence_number,
        entry_detail_sequence_number: entry_detail_sequence_number
      }) do
    %Return{
      reason_code: reason_code,
      original_entry_trace_number: original_entry_trace_number,
      date_of_death: date_of_death,
      original_rdfi_id: original_rdfi_id,
      addenda_information: addenda_information,
      addendum_sequence_number: addendum_sequence_number,
      entry_detail_sequence_number: entry_detail_sequence_number
    }
  end

  def to_detail(%Addendum{} = addedum) do
    map = addedum |> Map.from_struct()
    struct(Basic, map)
  end
end
