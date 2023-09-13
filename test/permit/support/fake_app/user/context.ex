defmodule Permit.FakeApp.User.Context do
  @moduledoc false
  alias Permit.FakeApp.User
  alias Permit.FakeApp.Repo

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
