defmodule Nacha.Batch do
  @moduledoc """
  A struct that represents a batch, containing the Batch Header, Batch Control,
  and Entry Detail records.

  Also includes utility functions for building and managing batches.
  """

  import Kernel, except: [to_string: 1]

  alias Nacha.Records.BatchHeader, as: Header
  alias Nacha.Records.BatchControl, as: Control
  alias Nacha.Records.EntryDetail
  alias Nacha.Entry

  @credit_codes ["22", "32"]
  @debit_codes ["27", "37"]

  @service_class_codes %{mixed: 200, credit_only: 220, debit_only: 225}

  defstruct [:header_record, :control_record, errors: [], entries: []]

  @typep entry_list :: list(Entry.t())

  @type t :: %__MODULE__{
          header_record: Header.t(),
          entries: entry_list,
          control_record: Control.t(),
          errors: list({atom, String.t()})
        }

  defmodule Offset do
    @type t :: %__MODULE__{
            routing_number: String.t(),
            account_number: String.t(),
            account_type: :checking | :savings
          }
    @enforce_keys [:routing_number, :account_number, :account_type]
    defstruct @enforce_keys
  end

  @doc """
  Build a valid batch with necessary generated values.
  """
  @spec build(entry_list, %{atom => any}, Offset.t() | nil) ::
          {:ok, t()} | {:error, t()}
  def build(entries, params, offset \\ nil) do
    params
    |> build_params(entries)
    |> do_build
    |> (fn batch ->
          if is_nil(offset) do
            batch
          else
            add_offset(batch, offset)
          end
        end).()
    |> validate
  end

  @spec to_string(__MODULE__.t()) :: String.t()
  def to_string(%__MODULE__{} = batch),
    do: batch |> to_iolist |> Kernel.to_string()

  @spec to_iolist(list(__MODULE__.t())) :: iolist
  def to_iolist([%__MODULE__{} | _] = batches),
    do: batches |> Stream.map(&to_iolist/1) |> Enum.intersperse("\n")

  @spec to_iolist(__MODULE__.t()) :: iolist
  def to_iolist(%__MODULE__{} = batch) do
    [
      Header.to_iolist(batch.header_record),
      "\n",
      Entry.to_iolist(batch.entries),
      "\n",
      Control.to_iolist(batch.control_record)
    ]
  end

  defp build_params(params, entries) do
    {credit_total, debit_total} = totals(entries)

    Map.merge(
      params,
      %{
        entries: entries,
        entry_count: length(entries),
        entry_hash: calculate_hash(entries),
        total_credits: credit_total,
        total_debits: debit_total,
        service_class_code: calculate_scc(credit_total, debit_total)
      }
    )
  end

  defp do_build(params) do
    %__MODULE__{
      header_record: build_header(params),
      entries: params.entries,
      control_record: build_control(params)
    }
  end

  @spec valid?(__MODULE__.t()) :: boolean
  def valid?(batch), do: match?({:ok, _}, validate(batch))

  defp build_header(params), do: Header |> struct(params)

  defp build_control(params), do: Control |> struct(params)

  defp get_offset_trace_number(entries) when is_list(entries) do
    entries
    |> Enum.at(Enum.count(entries) - 1)
    |> (& &1.record.trace_number).()
    |> :erlang.+(1)
  end

  # no need to add offset entry if total_debits and total_credits are the same
  defp add_offset(
         %__MODULE__{
           control_record: %{
             total_debits: amount,
             total_credits: amount
           }
         } = batch,
         _
       ) do
    batch
  end

  defp add_offset(
         %__MODULE__{
           header_record: header_record,
           entries: entries,
           control_record:
             %{
               total_debits: total_debits,
               total_credits: total_credits
             } = control_record
         },
         %Offset{
           account_type: account_type
         } = offset
       ) do
    {transaction_code, offset_amount, max_amount} =
      case {account_type, total_debits - total_credits} do
        {:checking, amount} when amount > 0 ->
          {"22", amount, total_debits}

        {:checking, amount} when amount < 0 ->
          {"27", -amount, total_credits}

        {:savings, amount} when amount > 0 ->
          {"32", amount, total_debits}

        {:savings, amount} when amount < 0 ->
          {"37", -amount, total_credits}
      end

    {rdfi_id, check_digit} = String.split_at(offset.routing_number, -1)

    offset_entry_detail = %EntryDetail{
      transaction_code: transaction_code,
      rdfi_id: rdfi_id,
      check_digit: String.to_integer(check_digit),
      account_number: offset.account_number,
      amount: offset_amount,
      individual_id: "",
      individual_name: "OFFSET",
      standard_entry_class: header_record.standard_entry_class,
      # ODFI routing number
      trace_id: header_record.odfi_id,
      trace_number: get_offset_trace_number(entries)
    }

    new_entries = entries ++ [Entry.build(offset_entry_detail, [])]

    %__MODULE__{
      header_record: %{
        header_record
        | service_class_code: @service_class_codes.mixed
      },
      entries: new_entries,
      control_record: %{
        control_record
        | service_class_code: @service_class_codes.mixed,
          entry_hash: calculate_hash(new_entries),
          entry_count: length(new_entries),
          total_debits: max_amount,
          total_credits: max_amount
      }
    }
  end

  defp validate(
         %{header_record: header, control_record: control, entries: entries} =
           batch
       ) do
    case {Header.validate(header), Control.validate(control),
          Enum.all?(entries, &Entry.valid?/1)} do
      {%{valid?: true} = header, %{valid?: true} = control, true} ->
        {:ok, %{batch | header_record: header, control_record: control}}

      {header, control, is_entries_valid} ->
        {:error, consolidate_errors(batch, header, control, is_entries_valid)}
    end
  end

  defp consolidate_errors(batch, header, control, is_entries_valid) do
    errors = Enum.uniq(header.errors ++ control.errors)

    errors =
      if is_entries_valid do
        errors
      else
        ["contain invalid entry" | errors]
      end

    %{
      batch
      | header_record: header,
        control_record: control,
        errors: errors
    }
  end

  defp totals(entries) do
    entries
    |> Enum.group_by(&credit_or_debit/1, &get_amount/1)
    |> sums()
  end

  defp calculate_hash(entries) do
    entries
    |> Enum.map(&String.to_integer(&1.record.rdfi_id))
    |> Enum.sum()
    |> Integer.digits()
    |> Enum.take(-10)
    |> Integer.undigits()
  end

  defp calculate_scc(0, debits) when debits > 0,
    do: @service_class_codes.debit_only

  defp calculate_scc(credits, 0) when credits > 0,
    do: @service_class_codes.credit_only

  defp calculate_scc(_, _), do: @service_class_codes.mixed

  defp credit_or_debit(%{record: %{transaction_code: tx}})
       when tx in @credit_codes,
       do: :credit

  defp credit_or_debit(%{record: %{transaction_code: tx}})
       when tx in @debit_codes,
       do: :debit

  defp credit_or_debit(_), do: :error

  defp get_amount(%{record: %{amount: amount}}), do: amount

  defp sums(amounts), do: {sum(amounts, :credit), sum(amounts, :debit)}
  defp sum(amounts, type), do: amounts |> Map.get(type, []) |> Enum.sum()
end
