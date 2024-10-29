defmodule RedisServer do
  @moduledoc """
  Implementation of a Redis server
  """

  use Application

  def start(_type, _args) do
    Supervisor.start_link([{Task, fn -> RedisServer.listen() end}], strategy: :one_for_one)
  end

  @doc """
  Listen for incoming connections
  """
  def listen() do
    {:ok, socket} = :gen_tcp.listen(6379, [:binary, active: false, reuseaddr: true])
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
    |> write_response
    handle_client(client)
  end

  defp parse({:error, msg}) do
    {:error, msg}
  end

  defp parse({message, socket}) do
    { Parser.parse(String.split(message, "\r\n")), socket }
  end

  defp write_response({:error, msg}) do
    {:error, msg}
  end

  defp write_response({response, socket}) do
    IO.inspect(response)
    :gen_tcp.send(socket, response)
  end

  defp read_command(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, line} -> {line, socket}
      {:error, msg} -> {:error, msg}
    end

  end
end