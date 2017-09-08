defmodule Nacha.Records.BatchControlTest do
  use ExUnit.Case, async: true

  alias Nacha.Records.BatchControl, as: Control

  @sample_record %Control{
    service_class_code: "200", entry_count: 12, entry_hash: 12345678,
    total_debits: 123456, total_credits: 123456, company_id: "1419871234",
    odfi_id: "09991234", batch_number: 1}
  @sample_string "820000001200123456780000001234560000001234561419871234" <>
    "                         099912340000001"

  test "formatting the record as a string" do
    string = Control.to_string(@sample_record)

    assert String.length(string) == 94
    assert string == @sample_string
  end
end
