defmodule RedisServer do
  @moduledoc """
  Implementation of a Redis server
  """

  use Application

  def start(_type, _args) do
    {:ok, _table} = :dets.open_file(:redis_db, [type: :set, file: String.to_atom("redis.dets")] )
    Supervisor.start_link([{Task, fn -> RedisServer.listen() end}], strategy: :one_for_one)
  end

  @doc """
  Listen for incoming connections
  """
  def listen() do
    {:ok, socket} = :gen_tcp.listen(6379, [:binary, active: false, reuseaddr: true])
    IO.puts "Started server on port 6379"
    accept(socket)
  end

  defp accept(socket) do
    case :gen_tcp.accept(socket) do
    {:ok, client} ->
      Task.start_link(fn -> handle_client(client) end)
      accept(socket)
    _ -> :error
    end
  end

  defp handle_client(client) do
    client
    |> read_command
    |> parse
    |> handle_command
    |> write_response
    handle_client(client)
  end

  defp parse({:error, msg}) do
    {:error, msg}
  end

  defp parse({message, socket}) do
    { Parser.parse(String.split(message, "\r\n")), socket }
  end

  defp handle_command({:error, msg}) do
    {:error, msg}
  end

  defp handle_command({command, socket}) do
    { CommandHandler.handle(command), socket }
  end

  defp write_response({:error, msg}) do
    {:error, msg}
  end

  defp write_response({response, socket}) do
    :gen_tcp.send(socket, response)
  end

  defp read_command(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, line} -> {line, socket}
      {:error, msg} -> {:error, msg}
    end

  end
end
