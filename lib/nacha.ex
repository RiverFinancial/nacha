defmodule Nacha do
  @moduledoc """
  Documentation for Nacha.
  """

  defdelegate build(entry_details, params), to: Nacha.File
  defdelegate parse(file_path), to: Nacha.File
end
