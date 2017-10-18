defmodule Nacha.Records.AddendumTest do
  use ExUnit.Case, async: true

  alias Nacha.Records.Addendum

  @sample_record %Addendum{
    payment_related_data: "Something something something",
    entry_detail_sequence_number: 1}
  @sample_string \
  "705Something something something                                                   00010000001"

  test "formatting the record as a string" do
    string = Addendum.to_string(@sample_record)

    assert String.length(string) == 94
    assert string == @sample_string
  end
end
