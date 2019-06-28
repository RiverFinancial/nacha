defmodule Nacha.File do
  @moduledoc """
  A struct that represents a file, containing the File Header, File Control,
  and batches.

  Also includes utility functions for building and managing files.
  """

  import Kernel, except: [to_string: 1]

  alias Nacha.{Batch, Records.EntryDetail}
  alias Nacha.Records.FileHeader, as: Header
  alias Nacha.Records.FileControl, as: Control
  alias Nacha.Parser

  @filler_record "\n9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999"

  defstruct [
    :header_record,
    :control_record,
    batches: [],
    failed: [],
    errors: []
  ]

  @type t :: %__MODULE__{
          header_record: Header.t(),
          batches: list(Batch.t()),
          control_record: Control.t(),
          errors: list({atom, String.t()})
        }

  @doc """
  Build a valid file with necessary generated values.
  """
  @spec build(list(EntryDetail.t()), %{atom => any}) ::
          {:ok, t()} | {:error, t()}
  def build(entries, params) do
    params
    |> build_params
    |> do_build(entries)
    |> validate
  end

  @spec parse(String.t()) ::
          {:ok, t()} | {:error, File.posix() | Parser.decode_error()}
  def parse(filePath) do
    with {:ok, content} <- File.read(filePath) do
      Parser.decode(content)
    end
  end

  @spec to_string(__MODULE__.t()) :: String.t()
  def to_string(%__MODULE__{} = file),
    do: file |> to_iolist |> Kernel.to_string()

  @spec to_iolist(__MODULE__.t()) :: iolist
  def to_iolist(%__MODULE__{} = file) do
    [
      Header.to_iolist(file.header_record),
      "\n",
      Batch.to_iolist(file.batches),
      "\n",
      Control.to_iolist(file.control_record),
      generate_filler_records(file)
    ]
  end

  @spec valid?(__MODULE__.t()) :: boolean
  def valid?(file), do: match?({:ok, _}, validate(file))

  defp build_params(params) do
    params
    |> Map.put_new_lazy(:creation_date, &Date.utc_today/0)
    |> Map.put_new_lazy(:creation_time, &Time.utc_now/0)
    |> Map.put_new_lazy(:effective_date, &Date.utc_today/0)
  end

  defp do_build(params, entries) do
    %__MODULE__{}
    |> build_header(params)
    |> build_batches(params, entries)
    |> build_control
  end

  defp build_header(file, params),
    do: Map.put(file, :header_record, struct(Header, params))

  defp build_batches(file, params, entries) do
    entries
    |> Enum.group_by(& &1.record.standard_entry_class)
    |> Enum.with_index(1)
    |> List.foldr(file, &build_batch(&1, &2, params))
  end

  defp build_batch({{sec, entries}, batch_num}, file, params) do
    entries
    |> Batch.build(%{
      batch_number: batch_num,
      company_id: params.immediate_origin,
      company_name: params.immediate_origin_name,
      effective_date: params.effective_date,
      descriptive_date: Map.get(params, :descriptive_date),
      # immediate_destination is of 9 digits(the first one is always blank so we exclude it. and the last digit is check digit)
      odfi_id: String.slice(params.immediate_destination, 0..7),
      standard_entry_class: sec
    })
    |> case do
      {:ok, batch} -> Map.update!(file, :batches, &[batch | &1])
      {:error, failed} -> Map.update!(file, :failed, &[failed | &1])
    end
  end

  defp build_control(file) do
    control_params =
      %{batch_count: length(file.batches)}
      |> add_entry_count(file)
      |> add_block_count
      |> add_entry_hash(file)
      |> add_total_debits(file)
      |> add_total_credits(file)

    %{file | control_record: struct(Control, control_params)}
  end

  defp generate_filler_records(%__MODULE__{} = file),
    do: file |> line_count |> fill_count |> generate_filler_records

  defp generate_filler_records(count)
       when is_integer(count) and count > 0,
       do: for(_ <- 1..count, do: @filler_record)

  defp generate_filler_records(0), do: []

  defp line_count(%__MODULE__{control_record: control}), do: line_count(control)

  defp line_count(%{entry_count: entry_count, batch_count: batch_count}),
    do: entry_count + 2 * batch_count + 2

  defp fill_count(lines) do
    case rem(lines, 10) do
      0 -> 0
      r -> 10 - r
    end
  end

  defp add_entry_count(params, %{batches: batches}) do
    Map.put(
      params,
      :entry_count,
      Enum.reduce(batches, 0, &(&2 + &1.control_record.entry_count))
    )
  end

  defp add_block_count(params) do
    count =
      (line_count(params) / 10)
      |> Float.ceil()
      |> trunc

    Map.put(params, :block_count, count)
  end

  defp add_entry_hash(params, %{batches: batches}) do
    hash =
      batches
      |> Stream.flat_map(fn batch ->
        Enum.map(batch.entries, & &1.record.rdfi_id)
      end)
      |> Enum.sum()
      |> Integer.digits()
      |> Enum.take(-10)
      |> Integer.undigits()

    Map.put(params, :entry_hash, hash)
  end

  defp add_total_debits(params, %{batches: batches}) do
    total =
      batches |> Stream.map(& &1.control_record.total_debits) |> Enum.sum()

    Map.put(params, :total_debits, total)
  end

  defp add_total_credits(params, %{batches: batches}) do
    total =
      batches |> Stream.map(& &1.control_record.total_credits) |> Enum.sum()

    Map.put(params, :total_credits, total)
  end

  defp validate(%{header_record: header, control_record: control} = file) do
    case {Header.validate(header), Control.validate(control)} do
      {%{valid?: true} = header, %{valid?: true} = control} ->
        {:ok, %{file | header_record: header, control_record: control}}

      {header, control} ->
        {:error, consolidate_errors(file, header, control)}
    end
  end

  defp consolidate_errors(file, header, control) do
    %{
      file
      | header_record: header,
        control_record: control,
        errors: Enum.uniq(header.errors ++ control.errors)
    }
  end
end
