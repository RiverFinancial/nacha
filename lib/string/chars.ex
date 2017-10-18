defimpl String.Chars, for: Nacha.Records.EntryDetail do
  def to_string(nil), do: ""
  def to_string(record), do: Nacha.Records.EntryDetail.to_string(record)
end

defimpl String.Chars, for: Nacha.Records.Addendum do
  def to_string(nil), do: ""
  def to_string(record), do: Nacha.Records.Addendum.to_string(record)
end

defimpl String.Chars, for: Nacha.Records.BatchHeader do
  def to_string(nil), do: ""
  def to_string(record), do: Nacha.Records.BatchHeader.to_string(record)
end

defimpl String.Chars, for: Nacha.Records.BatchControl do
  def to_string(nil), do: ""
  def to_string(record), do: Nacha.Records.BatchControl.to_string(record)
end

defimpl String.Chars, for: Nacha.Records.FileHeader do
  def to_string(nil), do: ""
  def to_string(record), do: Nacha.Records.FileHeader.to_string(record)
end

defimpl String.Chars, for: Nacha.Records.FileControl do
  def to_string(nil), do: ""
  def to_string(record), do: Nacha.Records.FileControl.to_string(record)
end

defimpl String.Chars, for: Nacha.File do
  def to_string(nil), do: ""
  def to_string(file), do: Nacha.File.to_string(file)
end

defimpl String.Chars, for: Nacha.Batch do
  def to_string(nil), do: ""
  def to_string(batch), do: Nacha.Batch.to_string(batch)
end
