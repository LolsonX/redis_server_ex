defmodule Parser do
  def parse([current_line | message]) do
    case _msg = parse_line(current_line) do
      %{type: :array} -> parse(message)
      %{type: :bulk_string} ->
        [command | params] = message
        IO.inspect("Command " <> command)
        case command  do
          "PING" -> {:ping}
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

  defp parse_echo([_val | message]) do
    {:echo, message}
  end

  defp parse_set(message) do
    {:set, message}
  end

  defp parse_get(message) do
    {:get, message}
  end
end
