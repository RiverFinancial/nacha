defmodule Nacha.FileTest do
  # test fixture copying from https://github.com/moov-io/ach/tree/master/test
  use ExUnit.Case, async: true

  alias Nacha.{Batch, Entry, Records.Addendum, Records.EntryDetail}
  alias Nacha.{Batch, Entry, Records.EntryDetail}
  alias Nacha.File, as: NachaFile
  alias Nacha.Utils

  @entries [
    Entry.build(%EntryDetail{
      transaction_code: "22",
      rdfi_id: "11111111",
      check_digit: Utils.get_check_digit_from_routing_number("11111111"),
      account_number: "012345678",
      amount: 100,
      individual_id: "0987654321",
      individual_name: "Bob Loblaw",
      standard_entry_class: "PPD",
      trace_id: "12345678",
      trace_number: 1
    }),
    Entry.build(
      %EntryDetail{
        transaction_code: "27",
        rdfi_id: "22222222",
        check_digit: Utils.get_check_digit_from_routing_number("22222222"),
        account_number: "123456789",
        amount: 200,
        individual_id: "9876543210",
        individual_name: "Bob Loblaw",
        standard_entry_class: "CCD",
        trace_id: "12345678",
        addenda_indicator: 1,
        trace_number: 2
      },
      [
        %Addendum{
          payment_related_data:
            "More Info                                                                       ",
          entry_detail_sequence_number: 1
        }
      ]
    ),
    Entry.build(%EntryDetail{
      transaction_code: "22",
      rdfi_id: "33333333",
      check_digit: Utils.get_check_digit_from_routing_number("33333333"),
      account_number: "234567890",
      amount: 100,
      individual_id: "8765432109",
      individual_name: "Bob Loblaw",
      standard_entry_class: "CCD",
      trace_id: "12345678",
      trace_number: 3
    }),
    Entry.build(%EntryDetail{
      transaction_code: "27",
      rdfi_id: "44444444",
      check_digit: Utils.get_check_digit_from_routing_number("44444444"),
      account_number: "345678901",
      amount: 200,
      individual_id: "7654321098",
      individual_name: "Bob Loblaw",
      standard_entry_class: "PPD",
      trace_id: "12345678",
      trace_number: 4
    }),
    Entry.build(%EntryDetail{
      transaction_code: "37",
      rdfi_id: "55555555",
      check_digit: Utils.get_check_digit_from_routing_number("55555555"),
      account_number: "456789012",
      amount: 444,
      individual_id: "6543210987",
      individual_name: "Bob Loblaw",
      standard_entry_class: "CCD",
      trace_id: "12345678",
      trace_number: 5
    }),
    Entry.build(%EntryDetail{
      transaction_code: "32",
      rdfi_id: "66666666",
      check_digit: Utils.get_check_digit_from_routing_number("66666666"),
      account_number: "567890123",
      amount: 200,
      individual_id: "5432109876",
      individual_name: "Bob Loblaw",
      standard_entry_class: "PPD",
      trace_id: "12345678",
      trace_number: 6
    }),
    Entry.build(%EntryDetail{
      transaction_code: "22",
      rdfi_id: "77777777",
      check_digit: Utils.get_check_digit_from_routing_number("77777777"),
      account_number: "678901234",
      amount: 666,
      individual_id: "4321098765",
      individual_name: "Bob Loblaw",
      standard_entry_class: "PPD",
      trace_id: "12345678",
      trace_number: 7
    }),
    Entry.build(%EntryDetail{
      transaction_code: "37",
      rdfi_id: "88888888",
      check_digit: Utils.get_check_digit_from_routing_number("88888888"),
      account_number: "789012345",
      amount: 300,
      individual_id: "3210987654",
      individual_name: "Bob Loblaw",
      standard_entry_class: "PPD",
      trace_id: "12345678",
      trace_number: 8
    })
  ]

  @valid_params %{
    effective_date: ~D[2017-01-01],
    immediate_destination: "123456789",
    immediate_origin: "1234567890",
    immediate_destination_name: "My Bank, Inc.",
    immediate_origin_name: "Sell Co",
    creation_date: ~D[2017-01-01],
    creation_time: ~T[12:00:00]
  }

  @offset %Batch.Offset{
    account_number: "012345678",
    routing_number: "073000228",
    account_type: :checking
  }

  @sample_file_string Enum.join(
                        [
                          "101 12345678912345678901701011200A094101My Bank, Inc.          Sell Co                        ",
                          "5200Sell Co                             1234567890CCD                170101   1123456780000001",
                          "627222222226123456789        00000002009876543210     Bob Loblaw              1123456780000002",
                          "705More Info                                                                       00010000001",
                          "622333333334234567890        00000001008765432109     Bob Loblaw              0123456780000003",
                          "637555555550456789012        00000004446543210987     Bob Loblaw              0123456780000005",
                          "820000000301111111100000000006440000000001001234567890                         123456780000001",
                          "5200Sell Co                             1234567890PPD                170101   1123456780000002",
                          "622111111118012345678        00000001000987654321     Bob Loblaw              0123456780000001",
                          "627444444442345678901        00000002007654321098     Bob Loblaw              0123456780000004",
                          "632666666668567890123        00000002005432109876     Bob Loblaw              0123456780000006",
                          "622777777776678901234        00000006664321098765     Bob Loblaw              0123456780000007",
                          "637888888884789012345        00000003003210987654     Bob Loblaw              0123456780000008",
                          "820000000502888888860000000005000000000009661234567890                         123456780000002",
                          "9000002000002000000080399999996000000001144000000001066                                       ",
                          "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
                          "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
                          "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
                          "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
                          "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999"
                        ],
                        "\n"
                      )

  @sample_file_string_with_offset Enum.join(
                                    [
                                      "101 12345678912345678901701011200A094101My Bank, Inc.          Sell Co                        ",
                                      "5200Sell Co                             1234567890CCD                170101   1123456780000001",
                                      "627222222226123456789        00000002009876543210     Bob Loblaw              1123456780000002",
                                      "705More Info                                                                       00010000001",
                                      "622333333334234567890        00000001008765432109     Bob Loblaw              0123456780000003",
                                      "637555555550456789012        00000004446543210987     Bob Loblaw              0123456780000005",
                                      "622073000228012345678        0000000544               OFFSET                  0123456780000006",
                                      "820000000401184111320000000006440000000006441234567890                         123456780000001",
                                      "5200Sell Co                             1234567890PPD                170101   1123456780000002",
                                      "622111111118012345678        00000001000987654321     Bob Loblaw              0123456780000001",
                                      "627444444442345678901        00000002007654321098     Bob Loblaw              0123456780000004",
                                      "632666666668567890123        00000002005432109876     Bob Loblaw              0123456780000006",
                                      "622777777776678901234        00000006664321098765     Bob Loblaw              0123456780000007",
                                      "637888888884789012345        00000003003210987654     Bob Loblaw              0123456780000008",
                                      "627073000228012345678        0000000466               OFFSET                  0123456780000009",
                                      "820000000602961889080000000009660000000009661234567890                         123456780000002",
                                      "9000002000002000000100414600040000000001610000000001610                                       ",
                                      "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
                                      "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
                                      "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999"
                                    ],
                                    "\n"
                                  )

  describe "building a file" do
    setup(context) do
      {:ok, file} = NachaFile.build(@entries, @valid_params)

      Map.put(context, :subject, file)
    end

    test "is valid with valid params", %{subject: file} do
      assert NachaFile.valid?(file)
    end

    test "builds a batch from the entries", %{subject: %{batches: batches}} do
      assert length(batches) == 2
      assert %Batch{} = hd(batches)
    end

    test "sets the batch count", %{subject: file} do
      assert file.control_record.batch_count == 2
    end

    test "sets the entry count", %{subject: file} do
      assert file.control_record.entry_count == 8
    end

    test "sets the block count", %{subject: file} do
      assert file.control_record.block_count == 2
    end

    test "calculates the entry hash", %{subject: file} do
      assert file.control_record.entry_hash == 399_999_996
    end

    test "calculates the debit total", %{subject: file} do
      assert file.control_record.total_debits == 1144
    end

    test "calculates the credit total", %{subject: file} do
      assert file.control_record.total_credits == 1066
    end
  end

  test "formatting a file as a string" do
    {:ok, nacha_file} = NachaFile.build(@entries, @valid_params)

    string = NachaFile.to_string(nacha_file)

    assert string == @sample_file_string
  end

  test "formatting a file as a string with offset" do
    {:ok, nacha_file} =
      NachaFile.build(@entries, @valid_params, with_offset: @offset)

    assert NachaFile.to_string(nacha_file) == @sample_file_string_with_offset
  end

  test "f" do
    entries = [
      Entry.build(%EntryDetail{
        transaction_code: "22",
        rdfi_id: "23138010",
        check_digit: Utils.get_check_digit_from_routing_number("23138010"),
        account_number: "12345678",
        amount: 100_000_000,
        individual_id: "",
        individual_name: "Receiver Account Name",
        standard_entry_class: "PPD",
        trace_id: "121042882",
        trace_number: 1
      })
    ]

    offset = %Batch.Offset{
      routing_number: "073000228",
      account_number: "123456789",
      account_type: :savings
    }

    valid_params = %{
      effective_date: ~D[2017-01-01],
      immediate_destination: "231380104",
      immediate_origin: "121042882",
      immediate_destination_name: "Federal Reserve Bank",
      immediate_origin_name: "My Bank Name",
      creation_date: ~D[2017-01-01],
      creation_time: ~T[12:00:00]
    }

    sample_file_string_with_offset =
      Enum.join(
        [
          "101 231380104121042882 1701011200A094101Federal Reserve Bank   My Bank Name                   ",
          "5200My Bank Name                        121042882 PPD                170101   1231380100000001",
          "62223138010412345678         0100000000               Receiver Account Name   0121042880000001",
          "637073000228123456789        0100000000               OFFSET                  0231380100000002",
          "82200000020030438032000100000000000100000000121042882                          231380100000001",
          "9000001000001000000020030438032000100000000000100000000                                       ",
          "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
          "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
          "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
          "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999"
        ],
        "\n"
      )

    {:ok, nacha_file} =
      NachaFile.build(entries, valid_params, with_offset: offset)

    assert NachaFile.to_string(nacha_file) == sample_file_string_with_offset
  end

  test "doesn't add filler records for a full block" do
    {:ok, file} = @entries |> Enum.slice(2, 4) |> NachaFile.build(@valid_params)

    lines = file |> NachaFile.to_string() |> String.split("\n")

    assert length(lines) == 10
    refute List.last(lines) =~ ~r/^9+$/
  end

  describe "parse/1" do
    test "return error if file doesn't exist" do
      assert {:error, :enoent} == NachaFile.parse("./non_existing")
    end

    test "return nacha file if file is in valid format" do
      {:ok, file} =
        NachaFile.build(
          @entries,
          @valid_params
        )

      assert {:ok, file} ==
               NachaFile.parse("./test/fixtures/achfiles/sample1.ach")
    end

    test "return error file if file is of invalid header format" do
      assert {:error, :invalid_file_header_format} ==
               NachaFile.parse("./test/fixtures/achfiles/incorrect-sample1.ach")
    end

    test "ach" do
      assert {:ok, _file} = NachaFile.parse("./test/fixtures/achfiles/ack.ach")
    end

    test "adv" do
      assert {:ok, _file} = NachaFile.parse("./test/fixtures/achfiles/adv.ach")
    end

    test "arc debit" do
      assert {:ok, _file} =
               NachaFile.parse("./test/fixtures/achfiles/arc-debit.ach")
    end

    test "boc" do
      assert {:ok, _file} = NachaFile.parse("./test/fixtures/achfiles/boc.ach")
    end

    test "ccd-debit" do
      assert {:ok, file} =
               NachaFile.parse("./test/fixtures/achfiles/ccd-debit.ach")
    end

    test "ppd-debit" do
      assert {:ok, _file} =
               NachaFile.parse("./test/fixtures/achfiles/ppd-debit.ach")
    end

    test "ppd-credit" do
      assert {:ok, _file} =
               NachaFile.parse("./test/fixtures/achfiles/ppd-credit.ach")
    end

    # containing return and notification of change addenda
    test "return-noc" do
      assert {:ok, file} =
               NachaFile.parse("./test/fixtures/achfiles/return-noc.ach")
    end
  end
end
