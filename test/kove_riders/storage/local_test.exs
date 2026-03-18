defmodule KoveRiders.Storage.LocalTest do
  use ExUnit.Case, async: true

  alias KoveRiders.Storage.Local

  @fixture_path Path.join([__DIR__, "../../support/fixtures/test-photo.jpg"])

  test "upload_file/3 copies to tmp and returns a relative URL" do
    key = "bike-photos/test-#{System.unique_integer([:positive])}.jpg"
    assert {:ok, url} = Local.upload_file(@fixture_path, key, "image/jpeg")
    assert url == "/uploads/#{key}"
    dest = Path.join([System.tmp_dir!(), "uploads", key])
    assert File.exists?(dest)
    File.rm(dest)
  end

  test "delete/1 removes the file and always returns :ok" do
    key = "bike-photos/delete-#{System.unique_integer([:positive])}.jpg"
    dest = Path.join([System.tmp_dir!(), "uploads", key])
    File.mkdir_p!(Path.dirname(dest))
    File.copy!(@fixture_path, dest)
    assert :ok = Local.delete(key)
    refute File.exists?(dest)
  end

  test "delete/1 returns :ok when file does not exist" do
    assert :ok = Local.delete("bike-photos/nonexistent-#{System.unique_integer([:positive])}.jpg")
  end

  test "public_url/1 returns relative URL" do
    assert Local.public_url("bike-photos/abc.jpg") == "/uploads/bike-photos/abc.jpg"
  end
end
