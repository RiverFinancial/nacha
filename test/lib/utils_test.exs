defmodule Nacha.UtilsTest do
  use ExUnit.Case, async: true

  alias Nacha.Utils

  # Ref: bankorganizer.com/list-of-routing-numbers
  @routing_number_check_digit_map %{
    # Wells Fargo Bank - IA
    "07300022" => 8,
    # Wells Fargo - CO
    "10200007" => 6,
    # USAA
    "31407426" => 9,
    # TD Bank CT
    "01110309" => 3
  }

  describe "get_check_digit_from_routing_number/1" do
    test "return correctly computed check digits" do
      for {routing_number, check_digit} <- @routing_number_check_digit_map do
        assert check_digit ==
                 Utils.get_check_digit_from_routing_number(routing_number)
      end
    end
  end
end
