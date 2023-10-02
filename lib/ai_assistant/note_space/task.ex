defmodule AiAssistant.NoteSpace.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :text, :string
    field :completed, :boolean, default: false
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:text, :completed,:user_id])
    |> validate_required([:text, :completed,:user_id])
  end
end
