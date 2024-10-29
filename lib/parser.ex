defmodule Parser do
  def parse([current_line | message]) do
    case _msg = parse_line(current_line) do
      %{type: :array} -> parse(message)
      %{type: :bulk_string} ->
        [command | params] = message
        IO.inspect("Command " <> command)
        case command  do
          "PING" -> "+PONG\r\n"
          "ECHO" -> parse_echo(params)
          "SET" -> parse_set(params)
          "GET" -> parse_get(params)
          _ -> parse(message)
        end
      _ -> ["+#{current_line}\r\n"] ++ Enum.join(message, "\r\n")
    end

  end

  def parse(_), do: nil

  defp parse_line(<<"*", args>>) do
    %{type: :array, size: Integer.parse(<<args::utf8>>)}
  end

  defp parse_line(<<"$", args>>) do
    {val, _rest} = Integer.parse(<<args::utf8>>)
    %{type: :bulk_string, size: val}
  end

  defp parse_line(<<"">>) do
    <<"">>
  end

  defp parse_line(args) do
    args
  end

  # Generate and handle related functions should be separated from parser
  # Parser should only parse the message and return a list of strings
  # And proper command in format {:command, parsed_params}
  # Then handler should implements handler functions for each command
  # and return a proper response data

  defp parse_echo([_val | message]) do
    msg = Enum.join(message)
    "$#{length(String.to_charlist(msg))}\r\n#{msg}\r\n"
  end

  defp parse_set(message) do
    message
      |> tl()
      |> Enum.take_every(2)
      |> insert_into_db
    "+OK\r\n"
  end

  defp insert_into_db([key, value])do
    :dets.insert(:redis_db, {key, value})
  end

  defp insert_into_db(data) do
    record = Enum.chunk_every(data, 2)
           |> Enum.flat_map(&convert_values/1)
           |> List.to_tuple
    :dets.insert(:redis_db, record)
  end

  defp convert_values([key, value]) do
    case String.downcase(key) do
      "px" -> [exp: Time.add(Time.utc_now(), String.to_integer(value), :millisecond)]
      _ -> [key, value]
    end
  end

  defp parse_get(message) do
    arg1 = Enum.at(message, 1)
    :dets.lookup(:redis_db, arg1)
          |> Enum.at(0)
          |> generate_get_response()
  end

  defp generate_get_response({_key, value, options}) do
    case options do
      {:exp, exp} ->
        if Time.after?(Time.utc_now(), exp), do: generate_get_response(nil), else: generate_response_message(value)
      _ -> generate_response_message(value)
    end
  end

  defp generate_get_response({_key, value}) do
    generate_response_message(value)
  end

  defp generate_get_response(nil) do
    "$-1\r\n"
  end

  defp generate_response_message(value) do
    "$#{length(String.to_charlist(value))}\r\n#{value}\r\n"
  end
end
