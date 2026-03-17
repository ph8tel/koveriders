defmodule KoveRiders.Currency do
  def format_cents(cents), do: format(cents)

  def format(nil), do: "Contact for pricing"

  def format(cents) when is_integer(cents) do
    dollars = div(cents, 100)

    formatted =
      dollars
      |> Integer.to_string()
      |> String.reverse()
      |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
      |> String.reverse()

    "$#{formatted}"
  end

  def parse(nil), do: nil

  def parse(msrp_str) when is_binary(msrp_str) do
    msrp_str
    |> String.replace("$", "")
    |> String.replace(",", "")
    |> String.to_integer()
    |> Kernel.*(100)
  end
end
