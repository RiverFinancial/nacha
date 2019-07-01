defmodule Nacha.Utils do
  @spec trim_non_empty_string(String.t()) :: String.t() | nil
  def trim_non_empty_string(str) do
    str = String.trim(str)

    if str == "" do
      nil
    else
      str
    end
  end
end
