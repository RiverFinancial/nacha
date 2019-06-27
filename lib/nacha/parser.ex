defmodule Nacha.Parser do
  @moduledoc """
  A Nacha Ach file Parser in pure Elixir
  """
  alias Nacha.File, as: NachaFile
  alias Nacha.{Batch, Records.EntryDetail, Records.BatchControl}
  alias Nacha.Records.FileHeader, as: Header
  alias Nacha.Entry
  alias Nacha.Records.BatchHeader, as: BatchHeader
  alias Nacha.Records.FileControl, as: Control

  @spec decode(iodata) :: {:ok, NachaFile.t()} | {:error, term()}
  def decode(input) do
    bin = IO.iodata_to_binary(input)

    with {:ok, header, rest_bin} <- parse_file_header(bin),
         {:ok, batches, rest_bin} <- parse_batches(rest_bin),
         {:ok, file_control} <- parse_file_control(rest_bin) do
      # {:ok, header, batches}
      {:ok,
       %NachaFile{
         header_record: header,
         batches: batches,
         control_record: file_control
       }}
    end
  end

  defp parse_file_control(<<
         ?9,
         batch_count::binary-size(6),
         block_count::binary-size(6),
         entry_count::binary-size(8),
         entry_hash::binary-size(10),
         total_debits::binary-size(12),
         total_credits::binary-size(12),
         reserved::binary-size(39),
         _rest::binary
       >>) do
    {batch_count, ""} = Integer.parse(batch_count)
    {block_count, ""} = Integer.parse(block_count)
    {entry_count, ""} = Integer.parse(entry_count)
    {total_debits, ""} = Integer.parse(total_debits)
    {total_credits, ""} = Integer.parse(total_credits)
    {entry_hash, ""} = Integer.parse(entry_hash)

    file_control =
      Control.validate(%Control{
        batch_count: batch_count,
        block_count: block_count,
        entry_count: entry_count,
        entry_hash: entry_hash,
        total_debits: total_debits,
        total_credits: total_credits,
        reserved: trim_non_empty_string(reserved)
      })

    if file_control.valid? do
      {:ok, file_control}
    else
      {:error, :invalid_file_control_format}
    end
  end

  defp parse_file_control(r) do
    r |> IO.inspect(label: "r")
    {:error, :invalid_file_control_format}
  end

  defp parse_file_header(
         <<?1, priority_code::binary-size(2), " ",
           immediate_destination::binary-size(9),
           immediate_origin::binary-size(10), creation_date::binary-size(6),
           creation_time::binary-size(4), file_id_modifier::binary-size(1),
           record_size::binary-size(3), block_size::binary-size(2),
           format_code::binary-size(1),
           immediate_destination_name::binary-size(23),
           immediate_origin_name::binary-size(23),
           reference_code::binary-size(8), "\n", rest_bin::binary>>
       ) do
    {record_size, ""} = Integer.parse(record_size)
    {block_size, ""} = Integer.parse(block_size)
    {:ok, creation_date} = parse_ach_date(creation_date)
    {:ok, creation_time} = parse_ach_time(creation_time)

    header =
      Header.validate(%Header{
        record_type_code: 1,
        priority_code: priority_code,
        immediate_destination: String.trim(immediate_destination),
        immediate_origin: String.trim(immediate_origin),
        creation_date: creation_date,
        creation_time: creation_time,
        file_id_modifier: file_id_modifier,
        record_size: record_size,
        block_size: block_size,
        format_code: format_code,
        immediate_destination_name: String.trim(immediate_destination_name),
        immediate_origin_name: String.trim(immediate_origin_name),
        reference_code: trim_non_empty_string(reference_code)
      })

    if header.valid? do
      {:ok, header, rest_bin}
    else
      {:error, :invalid_header}
    end
  end

  defp parse_file_header(_), do: {:error, :invalid_header_format}

  defp trim_non_empty_string(str) do
    str = String.trim(str)

    if str == "" do
      nil
    else
      str
    end
  end

  defp parse_ach_date(
         <<year::binary-size(2), month::binary-size(2), day::binary-size(2)>>
       ) do
    {year, ""} = Integer.parse("20" <> year)
    {month, ""} = Integer.parse(month)
    {day, ""} = Integer.parse(day)
    Date.from_erl({year, month, day})
  end

  defp parse_ach_time(<<hour::binary-size(2), minute::binary-size(2)>>) do
    {hour, ""} = Integer.parse(hour)
    {minute, ""} = Integer.parse(minute)
    Time.from_erl({hour, minute, 0})
  end

  defp parse_batches(bin) do
    do_parse_batches(bin, [])
  end

  defp do_parse_batches(
         <<?5, service_class_code::binary-size(3),
           company_name::binary-size(16), discretionary_data::binary-size(20),
           company_id::binary-size(10), standard_entry_class::binary-size(3),
           entry_description::binary-size(10), descriptive_date::binary-size(6),
           effective_date::binary-size(6), settlement_date::binary-size(3),
           originator_status::binary-size(1), odfi_id::binary-size(8),
           batch_number::binary-size(7), "\n", rest_bin::binary>>,
         acc
       ) do
    discretionary_data = trim_non_empty_string(discretionary_data)
    entry_description = trim_non_empty_string(entry_description)

    {batch_number, ""} = Integer.parse(batch_number)
    {service_class_code, ""} = Integer.parse(service_class_code)
    {:ok, effective_date} = parse_ach_date(effective_date)
    # julian date from 001 - 366
    settlement_date = String.trim(settlement_date)

    settlement_date =
      if settlement_date == "" do
        nil
      else
        {settlement_date, ""} = Integer.parse(settlement_date)
        settlement_date
      end

    descriptive_date = String.trim(descriptive_date)

    descriptive_date =
      if descriptive_date == "" do
        nil
      else
        {:ok, descriptive_date} = parse_ach_date(descriptive_date)
        descriptive_date
      end

    batch_header =
      BatchHeader.validate(%BatchHeader{
        record_type_code: 5,
        service_class_code: service_class_code,
        company_name: String.trim(company_name),
        discretionary_data: discretionary_data,
        company_id: String.trim(company_id),
        standard_entry_class: standard_entry_class,
        entry_description: entry_description,
        descriptive_date: descriptive_date,
        effective_date: effective_date,
        settlement_date: settlement_date,
        originator_status: originator_status,
        odfi_id: odfi_id,
        batch_number: batch_number
      })

    if batch_header.valid? do
      {:ok, entries, rest_bin} = parse_entries(rest_bin, standard_entry_class)
      {:ok, control_record, rest_bin} = parse_control_record(rest_bin)

      batch = %Batch{
        header_record: batch_header,
        entries: entries,
        control_record: control_record
      }

      do_parse_batches(rest_bin, [batch | acc])
    else
      {:error, :invalid_batch_header_format}
    end
  end

  defp do_parse_batches(
         rest_bin,
         acc
       ) do
    {:ok, acc |> Enum.reverse(), rest_bin}
  end

  defp parse_entries(bin, standard_entry_class) do
    do_parse_entries(bin, standard_entry_class, [])
  end

  defp do_parse_entries(
         <<?6, transaction_code::binary-size(2), rdfi_id::binary-size(8),
           check_digit::binary-size(1), account_number::binary-size(17),
           amount::binary-size(10), individual_id::binary-size(15),
           individual_name::binary-size(22), discretionary_data::binary-size(2),
           addenda_indicator::binary-size(1), trace_id::binary-size(8),
           trace_number::binary-size(7), "\n", rest_bin::binary>>,
         standard_entry_class,
         acc
       ) do
    transaction_code = String.trim(transaction_code)
    {rdfi_id, ""} = Integer.parse(rdfi_id)
    {check_digit, ""} = Integer.parse(check_digit)
    account_number = String.trim(account_number)
    {amount, ""} = Integer.parse(amount)
    individual_id = String.trim(individual_id)
    individual_name = String.trim(individual_name)
    discretionary_data = String.trim(discretionary_data)

    discretionary_data =
      if discretionary_data == "" do
        nil
      else
        discretionary_data
      end

    {addenda_indicator, ""} = Integer.parse(addenda_indicator)
    {trace_number, ""} = Integer.parse(trace_number)

    entry_detail =
      %EntryDetail{
        standard_entry_class: standard_entry_class,
        transaction_code: transaction_code,
        rdfi_id: rdfi_id,
        check_digit: check_digit,
        account_number: account_number,
        amount: amount,
        individual_id: individual_id,
        individual_name: individual_name,
        discretionary_data: discretionary_data,
        addenda_indicator: addenda_indicator,
        trace_id: trace_id,
        trace_number: trace_number
      }
      |> EntryDetail.validate()

    entry = %Entry{
      record: entry_detail
    }

    do_parse_entries(rest_bin, standard_entry_class, [entry | acc])
  end

  defp do_parse_entries(bin, _, acc) do
    {:ok, acc |> Enum.reverse(), bin}
  end

  defp parse_control_record(<<
         ?8,
         service_class_code::binary-size(3),
         entry_count::binary-size(6),
         entry_hash::binary-size(10),
         total_debits::binary-size(12),
         total_credits::binary-size(12),
         company_id::binary-size(10),
         message_auth_code::binary-size(19),
         reserved::binary-size(6),
         odfi_id::binary-size(8),
         batch_number::binary-size(7),
         "\n",
         rest_bin::binary
       >>) do
    {batch_number, ""} = Integer.parse(batch_number)
    {entry_count, ""} = Integer.parse(entry_count)
    {entry_hash, ""} = Integer.parse(entry_hash)
    {service_class_code, ""} = Integer.parse(service_class_code)
    {total_debits, ""} = Integer.parse(total_debits)
    {total_credits, ""} = Integer.parse(total_credits)
    reserved = String.trim(reserved)

    reserved =
      if reserved == "" do
        nil
      else
        reserved
      end

    message_auth_code = String.trim(message_auth_code)

    message_auth_code =
      if message_auth_code == "" do
        nil
      else
        message_auth_code
      end

    batch_control =
      BatchControl.validate(%BatchControl{
        service_class_code: service_class_code,
        entry_count: entry_count,
        entry_hash: entry_hash,
        total_debits: total_debits,
        total_credits: total_credits,
        company_id: company_id,
        message_auth_code: message_auth_code,
        reserved: reserved,
        odfi_id: odfi_id,
        batch_number: batch_number
      })

    if batch_control.valid? do
      {:ok, batch_control, rest_bin}
    else
      {:error, :invalid_batch_control}
    end
  end
end
