defmodule Nacha.Records.BatchHeaderTest do
  use ExUnit.Case, async: true

  alias Nacha.Records.BatchHeader, as: Header

  @sample_record %Header{
    service_class_code: "200", company_name: "My Best Comp.",
    discretionary_data: "Includes overtime", company_id: "1419871234",
    standard_entry_class: "PPD", entry_description: "Payroll",
    descriptive_date: ~D[2006-02-05], effective_date: ~D[2006-02-05],
    odfi_id: "09991234", batch_number: 1}
  @sample_string "5200My Best Comp.   Includes overtime   1419871234PPD" <>
    "Payroll   060205060205   1099912340000001"

  test "formatting the record as a string" do
    string = Header.to_string(@sample_record)

    assert String.length(string) == 94
    assert string == @sample_string
  end
end
