defmodule Permit.FakeApp.PhoenixActions do
  @moduledoc false
  use Permit.Actions

  @impl Permit.Actions
  def grouping_schema do
    %{
      new: [:create],
      index: [:read],
      show: [:read],
      edit: [:update]
    }
    |> Map.merge(crud_grouping())
  end

  def singular_actions,
    do: [:show, :edit, :new]
end
