defmodule Nacha.Records.AddendumTest do
  use ExUnit.Case, async: true

  alias Nacha.Records.Addendum

  @sample_record %Addendum{
    payment_related_data: "Something something something",
    entry_detail_sequence_number: 1
  }
  @sample_string "705Something something something                                                   00010000001"

  test "formatting the record as a string" do
    string = Addendum.to_string(@sample_record)

    assert String.length(string) == 94
    assert string == @sample_string
  end

  describe "to_detail/1" do
    test "return NotificationOfChange when the addendum_type_code is 98" do
      addedum = %Addendum{
        addendum_sequence_number: 1,
        addendum_type_code: 98,
        entry_detail_sequence_number: 1,
        payment_related_data:
          "C01121042880000001      121042881918171614                                      ",
        record_type_code: 7
      }

      assert %Addendum.NotificationOfChange{
               addendum_sequence_number: 1,
               corrected_data: "1918171614                   ",
               entry_detail_sequence_number: 1,
               original_entry_trace_number: "121042880000001",
               original_rdfi_id: "12104288",
               reason_code: "C01"
             } == Addendum.to_detail(addedum)
    end

    test "return Return when the addendum_type_code is 99" do
      addedum = %Addendum{
        addendum_sequence_number: 1,
        addendum_type_code: 99,
        entry_detail_sequence_number: 1,
        payment_related_data:
          "R03992222220280389      12114039                                                ",
        record_type_code: 7
      }

      assert %Addendum.Return{
               addenda_information:
                 "                                                ",
               addendum_sequence_number: 1,
               date_of_death: "      ",
               entry_detail_sequence_number: 1,
               original_entry_trace_number: "992222220280389",
               original_rdfi_id: "12114039",
               reason_code: "R03"
             } == Addendum.to_detail(addedum)
    end

    test "return Basic when the addendum_type_code is not either 99 or 98" do
      addedum = %Addendum{
        addendum_sequence_number: 1,
        addendum_type_code: 05,
        entry_detail_sequence_number: 1,
        payment_related_data:
          "MOREINFO2220280389      12114039                                                ",
        record_type_code: 7
      }

      assert %Addendum.Basic{
               addendum_sequence_number: 1,
               addendum_type_code: 05,
               entry_detail_sequence_number: 1,
               payment_related_data:
                 "MOREINFO2220280389      12114039                                                ",
               record_type_code: 7
             } == Addendum.to_detail(addedum)
    end
  end
end
