defmodule Nacha.Records.FileHeader do
  @moduledoc """
  A struct containing data for a file control record.
  """

  @required [
    :record_type_code, :priority_code, :immediate_destination,
    :immediate_origin, :creation_date, :creation_time, :file_id_modifier,
    :record_size, :block_size, :format_code, :immediate_destination_name,
    :immediate_origin_name]

  use Nacha.Record, fields: [
    {:record_type_code,           :number, 1,   1},
    {:priority_code,              :string, 2,   "01"},
    {:separator,                  :string, 1,   " "},
    {:immediate_destination,      :string, 9},
    {:immediate_origin,           :string, 10},
    {:creation_date,              :date,   6},
    {:creation_time,              :time,   4},
    {:file_id_modifier,           :string, 1,   "A"},
    {:record_size,                :number, 3,   94},
    {:block_size,                 :number, 2,   10},
    {:format_code,                :string, 1,   "1"},
    {:immediate_destination_name, :string, 23},
    {:immediate_origin_name,      :string, 23},
    {:reference_code,             :string, 8}]
end
