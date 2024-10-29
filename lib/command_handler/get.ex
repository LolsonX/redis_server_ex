defmodule CommandHandler.Get do
  def retrieve(key) do
    :dets.lookup(:redis_db, key)
    |> Enum.at(0)
  end

  def value_exists?([_key, _value | opts]) do
    Enum.all?(opts, &handle_opts/1)
  end

  def generate_response([_k, value | _]) do
    "$#{length(String.to_charlist(value))}\r\n#{value}\r\n"
  end

  def handle_opts({:exp, expiration_time}) do
    Time.before?(Time.utc_now(), expiration_time)
  end

  def handle_opts(_) do
    false
  end
end
