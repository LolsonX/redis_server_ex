defmodule CommandHandler do
  alias CommandHandler.Get, as: GetCmd
  alias CommandHandler.Set, as: SetCmd
  def handle({:ping}) do
    "+PONG\r\n"
  end

  def handle({:echo, message}) do
    "+#{message}\r\n"
  end

  def handle({:get, message}) do
    [_key_length, key | _] = message
    case GetCmd.retrieve(key) do
      nil -> "$-1\r\n"
      value -> if GetCmd.value_exists?(val = Tuple.to_list(value)), do: GetCmd.generate_response(val), else: "$-1\r\n"
    end
  end

  def handle({:set, message}) do
    record = tl(message)
      |> Enum.take_every(2)
      |> Enum.chunk_every(2)
      |> Enum.flat_map(&SetCmd.convert_values/1)
      |> List.to_tuple
    :dets.insert(:redis_db, record)
    "+OK\r\n"
  end

  def handle() do
    "+OK\r\n"
  end
end
