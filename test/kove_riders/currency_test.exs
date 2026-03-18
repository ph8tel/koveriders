defmodule KoveRiders.CurrencyTest do
  use ExUnit.Case, async: true

  alias KoveRiders.Currency

  describe "format/1" do
    test "nil returns contact prompt" do
      assert Currency.format(nil) == "Contact for pricing"
    end

    test "zero" do
      assert Currency.format(0) == "$0"
    end

    test "whole dollars" do
      assert Currency.format(5000) == "$50"
    end

    test "truncates cents" do
      assert Currency.format(5099) == "$50"
    end

    test "adds thousands separator" do
      assert Currency.format(100_000) == "$1,000"
    end

    test "large amount" do
      assert Currency.format(1_000_000) == "$10,000"
    end
  end

  describe "parse/1" do
    test "plain integer string" do
      assert Currency.parse("1500") == 150_000
    end

    test "strips dollar sign and comma" do
      assert Currency.parse("$1,500") == 150_000
    end

    test "zero" do
      assert Currency.parse("0") == 0
    end
  end
end
