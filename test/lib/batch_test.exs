defmodule Nacha.BatchTest do
  use ExUnit.Case, async: true

  alias Nacha.{Batch, Entry, Records.Addendum, Records.EntryDetail}
  alias Nacha.Records.BatchHeader, as: Header
  alias Nacha.Records.BatchControl, as: Control

  @credit_entries [
    %Entry{
      record: %EntryDetail{
        transaction_code: "22",
        rdfi_id: 99_999_999,
        check_digit: 9,
        account_number: "012345678",
        amount: 100,
        individual_id: "1234567890",
        individual_name: "Bob Loblaw",
        addenda_indicator: 1,
        trace_id: "12345678",
        trace_number: 1
      },
      addenda: [
        %Addendum{
          payment_related_data: "This one has some additional data",
          entry_detail_sequence_number: 1
        }
      ]
    },
    %Entry{
      record: %EntryDetail{
        transaction_code: "32",
        rdfi_id: 99_999_999,
        check_digit: 9,
        account_number: "012345678",
        amount: 200,
        individual_id: "1234567890",
        individual_name: "Bob Loblaw",
        trace_id: "12345678",
        trace_number: 2
      }
    }
  ]
  @debit_entries [
    %Entry{
      record: %EntryDetail{
        transaction_code: "27",
        rdfi_id: 99_999_999,
        check_digit: 9,
        account_number: "012345678",
        amount: 200,
        individual_id: "1234567890",
        individual_name: "Bob Loblaw",
        trace_id: "12345678",
        trace_number: 3
      }
    },
    %Entry{
      record: %EntryDetail{
        transaction_code: "37",
        rdfi_id: 99_999_999,
        check_digit: 9,
        account_number: "012345678",
        amount: 300,
        individual_id: "1234567890",
        individual_name: "Bob Loblaw",
        trace_id: "12345678",
        trace_number: 4
      }
    }
  ]
  @entries @credit_entries ++ @debit_entries
  @valid_params %{
    batch_number: 1,
    company_id: 1_234_567_890,
    company_name: "Sell Co",
    effective_date: ~D[2017-01-01],
    odfi_id: 12_345_678,
    standard_entry_class: "PPD"
  }
  @sample_batch_string Enum.join(
                         [
                           "5200Sell Co                             1234567890PPD                170101   1123456780000001",
                           "622999999999012345678        00000001001234567890     Bob Loblaw              1123456780000001",
                           "705This one has some additional data                                               00010000001",
                           "632999999999012345678        00000002001234567890     Bob Loblaw              0123456780000002",
                           "627999999999012345678        00000002001234567890     Bob Loblaw              0123456780000003",
                           "637999999999012345678        00000003001234567890     Bob Loblaw              0123456780000004",
                           "820000000403999999960000000005000000000003001234567890                         123456780000001"
                         ],
                         "\n"
                       )

  describe "building a batch" do
    test "sets the entry count" do
      {:ok, batch} = Batch.build(@entries, @valid_params)

      assert batch.control_record.entry_count == 4
    end

    test "sets the credit & debit totals" do
      {:ok, batch} = Batch.build(@entries, @valid_params)

      assert batch.control_record.total_credits == 300
      assert batch.control_record.total_debits == 500
    end

    test "sets the service class code for mixed entries" do
      {:ok, batch} = Batch.build(@entries, @valid_params)

      assert batch.header_record.service_class_code == 200
      assert batch.control_record.service_class_code == 200
    end

    test "sets the service class code for only credit entries" do
      {:ok, batch} = Batch.build(@credit_entries, @valid_params)

      assert batch.header_record.service_class_code == 220
      assert batch.control_record.service_class_code == 220
    end

    test "sets the service class code for only debit entries" do
      {:ok, batch} = Batch.build(@debit_entries, @valid_params)

      assert batch.header_record.service_class_code == 225
      assert batch.control_record.service_class_code == 225
    end

    test "sets the entry hash" do
      {:ok, batch} = Batch.build(@entries, @valid_params)

      assert batch.control_record.entry_hash == 399_999_996
    end

    test "limits the entry hash to the 10 least significant digits" do
      {:ok, batch} =
        @entries
        |> Enum.map(&update_rdfi(&1, 9_999_999_999))
        |> Batch.build(@valid_params)

      assert batch.control_record.entry_hash == 9_999_999_996
    end

    defp update_rdfi(entry, rdfi_id),
      do: %{entry | record: %{entry.record | rdfi_id: rdfi_id}}

    test "generates the full header record" do
      {:ok, %{header_record: header}} = Batch.build(@entries, @valid_params)

      assert %Header{} = header
      assert header.company_name == @valid_params.company_name
      assert header.company_id == @valid_params.company_id
      assert header.effective_date == @valid_params.effective_date
      assert header.odfi_id == @valid_params.odfi_id
      assert header.batch_number == @valid_params.batch_number
    end

    test "generates the full control record" do
      {:ok, %{control_record: control}} = Batch.build(@entries, @valid_params)

      assert %Control{} = control
      assert control.company_id == @valid_params.company_id
      assert control.odfi_id == @valid_params.odfi_id
      assert control.batch_number == @valid_params.batch_number
    end

    test "validates required values" do
      {:error, batch} = Batch.build(@entries, %{})

      refute Batch.valid?(batch)
      assert {:company_id, "is required"} in batch.errors
      assert {:company_name, "is required"} in batch.errors
      assert {:effective_date, "is required"} in batch.errors
      assert {:odfi_id, "is required"} in batch.errors
      assert {:standard_entry_class, "is required"} in batch.errors
    end
  end

  test "formatting a batch as a string" do
    {:ok, batch} = Batch.build(@entries, @valid_params)

    string = Batch.to_string(batch)

    assert string == @sample_batch_string
  end
end
