defmodule Nacha.Record do
  @moduledoc """
  A use macro for building and formatting NACHA records.
  """

  defmacro __using__(opts) do
    quote do
      import Kernel, except: [to_string: 1]

      @keys unquote(Keyword.get(opts, :keys))

      defstruct Enum.map(@keys, fn
        {key, _, _} -> key
        {key, _, _, default} -> {key, default}
      end)

      @type t :: %__MODULE__{}

      @spec to_string(__MODULE__.t) :: String.t
      def to_string(%__MODULE__{} = record),
        do: unquote(__MODULE__).to_string(record, @keys)

      @spec to_iolist(__MODULE__.t) :: iolist
      def to_iolist(%__MODULE__{} = record),
        do: unquote(__MODULE__).to_iolist(record, @keys)
    end
  end

  @typep key_def :: {atom, atom, integer} | {atom, atom, integer, any}

  @spec to_string(struct, list(key_def)) :: String.t
  def to_string(record, keys), do: record |> to_iolist(keys) |> to_string

  @spec to_iolist(struct, list(key_def)) :: iolist
  def to_iolist(record, keys),
    do: Enum.reduce(keys, [], &([&2, format_field(record, &1)]))

  defp format_field(record, {key, type, length, _}),
    do: format_field(record, {key, type, length})
  defp format_field(record, {key, type, length}),
    do: record |> Map.get(key, "") |> format_value(length, type) |> pad(length, type)

  defp format_value(date, _, :date),
    do: date |> Date.to_iso8601(:basic) |> String.slice(2, 6)
  defp format_value(time, _, :time),
    do: time |> Time.to_iso8601(:basic) |> String.slice(0, 4)
  defp format_value(value, length, _type),
    do: value |> to_string() |> String.slice(0, length)

  defp pad(val, length, :number), do: String.pad_leading(val, length, "0")
  defp pad(val, length, :string), do: String.pad_trailing(val, length, " ")
  defp pad(val, _, _), do: val
end
