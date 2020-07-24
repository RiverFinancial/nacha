defmodule Nacha.Entry do
  @moduledoc """
  A struct containing an entry detail record and, optionally,
  addenda records and additional metadata.
  """

  import Kernel, except: [to_string: 1]

  alias Nacha.Records.{EntryDetail, Addendum}

  defstruct [:record, addenda: []]

  @type t :: %__MODULE__{record: EntryDetail.t(), addenda: list(Addendum.t())}

  @doc """
  struct constructor function and run validation by default
  """
  @spec build(EntryDetail.t(), list(Addendum.t())) :: t()
  def build(entry_detail, addenda \\ []) do
    %__MODULE__{
      record: entry_detail |> EntryDetail.validate(),
      addenda: addenda |> Enum.map(&Addendum.validate/1)
    }
  end

  @spec valid?(t()) :: boolean()
  def valid?(entry) do
    Enum.all?([entry.record | entry.addenda], & &1.valid?)
  end

  @spec to_string(__MODULE__.t()) :: String.t()
  def to_string(%__MODULE__{} = entry),
    do: entry |> to_iolist |> Kernel.to_string()

  @spec to_iolist(__MODULE__.t() | list(__MODULE__.t())) :: iolist()
  def to_iolist(entries) when is_list(entries),
    do: entries |> Stream.map(&to_iolist/1) |> Enum.intersperse("\n")

  def to_iolist(%__MODULE__{addenda: []} = entry),
    do: EntryDetail.to_iolist(entry.record)

  def to_iolist(%__MODULE__{} = entry) do
    [
      EntryDetail.to_iolist(entry.record),
      "\n",
      Addendum.to_iolist(entry.addenda)
    ]
  end
end
