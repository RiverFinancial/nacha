defmodule Nacha.Utils do
  @spec trim_non_empty_string(String.t()) :: String.t() | nil
  def trim_non_empty_string(str) do
    str = String.trim(str)

    if str == "" do
      nil
    else
      str
    end
  end

  # ref: https://en.wikipedia.org/wiki/Routing_transit_number#Check_digit
  @spec get_check_digit_from_rdfi_routing_number(String.t()) :: integer()
  def get_check_digit_from_rdfi_routing_number(routing_number)
      when is_binary(routing_number) and byte_size(routing_number) == 8 do
    routing_number
    |> String.to_integer()
    |> Integer.digits()
    # to padding in the beginning with 0 for routing_number in integer that's less than 8 digits
    |> (&(List.duplicate(0, 8) ++ &1)).()
    |> Enum.take(-8)
    # weighting factor for each digit specified in Nacha
    |> Enum.zip([3, 7, 1, 3, 7, 1, 3, 7])
    |> Enum.map(fn {d, w} -> d * w end)
    |> Enum.sum()
    |> :erlang.rem(10)
    |> (&(10 - &1)).()
  end
end
