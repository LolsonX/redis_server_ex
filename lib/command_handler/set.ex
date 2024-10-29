defmodule CommandHandler.Set do
  def convert_values([key, value]) do
    case String.downcase(key) do
      "px" -> [exp: Time.add(Time.utc_now(), String.to_integer(value), :millisecond)]
      _ -> [key, value]
    end
  end

end
