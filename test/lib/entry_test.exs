defmodule Nacha.EntryTest do
  use ExUnit.Case, async: true

  alias Nacha.{Entry, Records.Addendum, Records.EntryDetail}

  @addendum %Addendum{}
  @record %EntryDetail{}
  @entry %Entry{record: @record, addenda: [@addendum]}
  @string to_string(@record) <> "\n" <> to_string(@addendum)

  test "formatting the entry detail as a string" do
    string = Entry.to_string(@entry)

    assert string == @string
  end
end
