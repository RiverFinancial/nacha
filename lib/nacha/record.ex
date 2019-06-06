defmodule Nacha.Record do
  @moduledoc """
  A use macro for building and formatting NACHA records.
  """

  defmacro __using__(opts) do
    quote do
      import Kernel, except: [to_string: 1]

      @fields unquote(Keyword.get(opts, :fields))

      if __MODULE__ |> Module.get_attribute(:required) |> is_nil() do
        Module.put_attribute(__MODULE__, :required, [])
      end

      defstruct Enum.map(@fields, fn
                  {key, _, _} -> key
                  {key, _, _, default} -> {key, default}
                end) ++ [errors: [], valid?: false]

      @type t :: %__MODULE__{}

      @spec validate(__MODULE__.t()) :: __MODULE__.t()
      def validate(record),
        do: unquote(__MODULE__).validate_required(record, @required)

      @spec to_string(__MODULE__.t()) :: String.t()
      def to_string(%__MODULE__{} = record),
        do: unquote(__MODULE__).to_string(record, @fields)

      @spec to_iolist(__MODULE__.t()) :: iolist
      def to_iolist(%__MODULE__{} = record),
        do: unquote(__MODULE__).to_iolist(record, @fields)

      def to_iolist([%__MODULE__{} | _] = records),
        do: unquote(__MODULE__).to_iolist(records, @fields)

      def to_iolist([]), do: []
    end
  end

  @typep key_def :: {atom, atom, integer} | {atom, atom, integer, any}

  @spec validate_required(struct, list(atom)) :: struct
  def validate_required(record, required) do
    validated =
      Enum.reduce(required, record, fn key, acc ->
        if is_nil(Map.get(acc, key)),
          do: Map.update!(acc, :errors, &[{key, "is required"} | &1]),
          else: acc
      end)

    %{validated | valid?: length(validated.errors) == 0}
  end

  @spec to_string(struct, list(key_def)) :: String.t()
  def to_string(record, keys), do: record |> to_iolist(keys) |> to_string

  @spec to_iolist(struct, list(key_def)) :: iolist
  def to_iolist(records, keys) when is_list(records),
    do: records |> Stream.map(&to_iolist(&1, keys)) |> Enum.intersperse("\n")

  def to_iolist(record, keys),
    do: Enum.reduce(keys, [], &[&2, format_field(record, &1)])

  defp format_field(record, {key, type, length, _}),
    do: format_field(record, {key, type, length})

  defp format_field(record, {key, type, length}),
    do:
      record
      |> Map.get(key, "")
      |> format_value(length, type)
      |> pad(length, type)

  defp format_value(nil, length, type)
       when type in [:date, :time],
       do: format_value(nil, length, :string)

  defp format_value(date, _, :date),
    do: date |> Date.to_iso8601(:basic) |> String.slice(2, 6)

  defp format_value(time, _, :time),
    do: time |> Time.to_iso8601(:basic) |> String.slice(0, 4)

  defp format_value(value, length, _type),
    do: value |> to_string() |> String.slice(0, length)

  defp pad(val, length, :number), do: String.pad_leading(val, length, "0")
  defp pad(val, length, _), do: String.pad_trailing(val, length, " ")
end
