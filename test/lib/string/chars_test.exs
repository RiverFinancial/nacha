defmodule String.CharsTest do
  use ExUnit.Case, async: true

  alias Nacha.{Batch, File}
  alias Nacha.Records.{
    EntryDetail, BatchHeader, BatchControl, FileHeader, FileControl}

  @sample_entry %EntryDetail{
    transaction_code: "22", rdfi_id: 11111111, check_digit: 9,
    account_number: "012345678", amount: 100, individual_id: "0987654321",
    individual_name: "Bob Loblaw", standard_entry_class: "PPD",
    trace_number: "1234567890"}
  @valid_file_params %{
    batch_number: 1, company_id: 1234567890, company_name: "Sell Co",
    effective_date: ~D[2017-01-01], odfi_id: 12345678,
    standard_entry_class: "PPD"}
  @valid_batch_params %{
    effective_date: ~D[2017-01-01], immediate_destination: 123456789,
    immediate_origin: 1234567890, immediate_destination_name: "My Bank, Inc.",
    immediate_origin_name: "Sell Co", creation_date: ~D[2017-01-01],
    creation_time: ~T[12:00:00]}

  test "String.Chars implementation for NACHA records" do
    for mod <- [EntryDetail, BatchHeader, BatchControl, FileHeader, FileControl] do
      record = struct(mod)

      assert to_string(record) == mod.to_string(record)
    end
  end

  test "String.Chars implementation for NACHA batches" do
    {:ok, batch} = Batch.build([@sample_entry], @valid_file_params)

    assert to_string(batch) == Batch.to_string(batch)
  end

  test "String.Chars implementation for NACHA file" do
    {:ok, file} = File.build([@sample_entry], @valid_batch_params)

    assert to_string(file) == File.to_string(file)
  end
end
