defmodule Nacha.RecordTest do
  use ExUnit.Case, async: true

  defmodule TestRecord do
    @required [:str]
    use Nacha.Record, fields: [{:num, :number, 2}, {:str, :string, 5}]
  end

  test "is invalid by default" do
    refute %TestRecord{}.valid?
  end

  test "validates required fields" do
    record = TestRecord.validate(%TestRecord{})

    refute record.valid?
    assert length(record.errors) == 1
    assert {:str, "is required"} in record.errors
  end

  test "converts to iolist of formatted fields" do
    list = %TestRecord{num: 1, str: "two"} |> TestRecord.to_iolist

    assert list == [[[], "01"], "two  "]
  end

  test "converts to string based on field formats" do
    string = %TestRecord{num: 1, str: "two"} |> TestRecord.to_string

    assert string == "01two  "
  end
end
