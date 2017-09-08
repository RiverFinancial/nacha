defmodule Nacha.Records.FileControlTest do
  use ExUnit.Case, async: true

  alias Nacha.Records.FileControl, as: Control

  @sample_record %Control{
    batch_count: 4, block_count: 5, entry_count: 42, entry_hash: 12345678,
    total_debits: 123456, total_credits: 123456}
  @sample_string "9000004000005000000420012345678000000123456000000123456" <>
    "                                       "

  test "formatting the record as a string" do
    string = Control.to_string(@sample_record)

    assert String.length(string) == 94
    assert string == @sample_string
  end
end
