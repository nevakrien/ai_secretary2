defmodule AiAssistant.NoteSpace.Event do
  use Ecto.Schema
  import Ecto.Changeset
  alias AiAssistant.Repo

  schema "events" do
    field :date, :utc_datetime
    field :description, :string
    belongs_to :user, AiAssistant.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:description, :date])
    |> validate_required([:description, :date])
  end

  def create_event(attrs \\ %{}) do
    %AiAssistant.NoteSpace.Event{}
    |> changeset(attrs) 
    |> Repo.insert()
  end
end
