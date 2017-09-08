defmodule Nacha.Records.FileHeaderTest do
  use ExUnit.Case, async: true

  alias Nacha.Records.FileHeader, as: Header

  @sample_record %Header{
    immediate_destination: "123456789", immediate_origin: "0123456789",
    creation_date: ~D[2017-01-01], creation_time: ~T[12:00:00],
    immediate_destination_name: "Receiving Bank",
    immediate_origin_name: "First Origination Bank of Internet",
    reference_code: "12345678"}
  @sample_string "101 12345678901234567891701011200A094101" <>
    "Receiving Bank         First Origination Bank 12345678"

  test "formatting the record as a string" do
    string = Header.to_string(@sample_record)

    assert String.length(string) == 94
    assert string == @sample_string
  end
end
