defmodule Nacha.Records.EntryDetailTest do
  use ExUnit.Case, async: true

  alias Nacha.Records.EntryDetail

  @sample_record %EntryDetail{
    transaction_code: "27", rdfi_id: 12345678, check_digit: 9,
    account_number: "012345678", amount: "9999", individual_id: "1234567890",
    individual_name: "Bob Loblaw", trace_number: "1234567890"}
  @sample_string "627123456789012345678        00000099991234567890     " <>
    "Bob Loblaw              01234567890     "

  test "formatting the record as a string" do
    string = EntryDetail.to_string(@sample_record)

    assert String.length(string) == 94
    assert string == @sample_string
  end
end
