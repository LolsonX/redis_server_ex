defmodule Parser do
  def parse([current_line | message]) do
    case _msg = parse_line(current_line) do
      %{type: :array} -> parse(message)
      %{type: :bulk_string} ->
        [command | params] = message
        IO.inspect(command)
        case command  do
          "PING" -> "+PONG\r\n"
          "ECHO" -> handle_echo(params)
          "SET" -> handle_set(params)
          "GET" -> "+OK\r\n"
          _ -> parse(message)
        end
      _ -> ["+#{current_line}\r\n"] ++ Enum.join(message, "\r\n")
    end

  end

  def parse(_), do: nil

  defp handle_echo([_val | message]) do
    msg = Enum.join(message)
    "$#{length(String.to_charlist(msg))}\r\n#{msg}\r\n"
  end

  defp handle_set(message) do
    arg1 = Enum.at(message, 1)
    arg2 = Enum.at(message, 3)
    IO.inspect(arg1)
    IO.inspect(arg2)
    "+OK\r\n"
  end

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
end
