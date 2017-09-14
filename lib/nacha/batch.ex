defmodule Nacha.Batch do
  @moduledoc """
  A struct that represents a batch, containing the Batch Header, Batch Control,
  and Entry Detail records.

  Also includes utility functions for building and managing batches.
  """

  import Kernel, except: [to_string: 1]

  alias Nacha.Records.EntryDetail
  alias Nacha.Records.BatchHeader, as: Header
  alias Nacha.Records.BatchControl, as: Control

  @credit_codes ["22", "32"]
  @debit_codes ["27", "37"]

  @service_class_codes %{mixed: 200, credit_only: 220, debit_only: 225}

  defstruct [:header_record, :control_record, errors: [], entries: []]

  @typep entry_list :: list(EntryDetail.t)

  @type t :: %__MODULE__{
    header_record: Header.t, entries: entry_list, control_record: Control.t,
    errors: list({atom, String.t})}

  @doc """
  Build a valid batch with necessary generated values.
  """
  @spec build(entry_list, %{atom => any}) :: __MODULE__.t
  def build(entries, params) do
    params
    |> build_params(entries)
    |> do_build
    |> validate
  end

  @spec to_string(__MODULE__.t) :: String.t
  def to_string(%__MODULE__{} = batch),
    do: batch |> to_iolist |> Kernel.to_string

  @spec to_iolist(list(__MODULE__.t)) :: iolist
  def to_iolist([%__MODULE__{} | _] = batches),
    do: batches |> Stream.map(&to_iolist/1) |> Enum.intersperse("\n")
  @spec to_iolist(__MODULE__.t) :: iolist
  def to_iolist(%__MODULE__{} = batch) do
    [Header.to_iolist(batch.header_record), "\n",
     EntryDetail.to_iolist(batch.entries), "\n",
     Control.to_iolist(batch.control_record)]
  end

  defp build_params(params, entries) do
    {credit_total, debit_total} = totals(entries)
    Map.merge(
      params,
      %{entries: entries,
        entry_count: length(entries),
        entry_hash: calculate_hash(entries),
        total_credits: credit_total,
        total_debits: debit_total,
        service_class_code: calculate_scc(credit_total, debit_total)})
  end

  defp do_build(params) do
    %__MODULE__{
      header_record: build_header(params),
      entries: params.entries,
      control_record: build_control(params)}
  end

  @spec valid?(__MODULE__.t) :: boolean
  def valid?(batch), do: match?({:ok, _}, validate(batch))

  defp build_header(params), do: Header |> struct(params)

  defp build_control(params), do: Control |> struct(params)

  defp validate(%{header_record: header, control_record: control} = batch) do
    case {Header.validate(header), Control.validate(control)} do
      {%{valid?: true} = header, %{valid?: true} = control} ->
         {:ok, %{batch | header_record: header, control_record: control}}

      {header, control} ->
        {:error, consolidate_errors(batch, header, control)}
    end
  end

  defp consolidate_errors(batch, header, control) do
    %{batch |
      header_record: header,
      control_record: control,
      errors: Enum.uniq(header.errors ++ control.errors)}
  end

  defp totals(entries) do
    entries
    |> Enum.group_by(&credit_or_debit/1, &Map.get(&1, :amount, 0))
    |> sums()
  end

  defp calculate_hash(entries) do
    entries
    |> Enum.reduce(0, &(&2 + &1.rdfi_id))
    |> Integer.digits
    |> Enum.take(-10)
    |> Integer.undigits
  end

  defp calculate_scc(0, debits) when debits > 0,
    do: @service_class_codes.debit_only
  defp calculate_scc(credits, 0) when credits > 0,
    do: @service_class_codes.credit_only
  defp calculate_scc(_, _), do: @service_class_codes.mixed

  defp credit_or_debit(%{transaction_code: tx})
  when tx in @credit_codes, do: :credit
  defp credit_or_debit(%{transaction_code: tx})
  when tx in @debit_codes, do: :debit
  defp credit_or_debit(_), do: :error

  defp sums(amounts), do: {sum(amounts, :credit), sum(amounts, :debit)}

  defp sum(amounts, type), do: amounts |> Map.get(type, []) |> Enum.sum
end
