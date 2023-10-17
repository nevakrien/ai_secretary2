defmodule AiAssistant.NoteSpace.Event do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
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
    |> cast(attrs, [:description, :date,:user_id])
    |> validate_required([:description, :date,:user_id])
  end

  def create_event(attrs \\ %{}) do
    %AiAssistant.NoteSpace.Event{}
    |> changeset(attrs) 
    |> Repo.insert()
  end

  def get_events(user_id, start_datetime, end_datetime, limit) do
    query = from(e in AiAssistant.NoteSpace.Event,
          where: e.user_id == ^user_id and
                 e.date >= ^start_datetime and
                 e.date <= ^end_datetime,
          order_by: [asc: e.date],
          limit: ^limit)

    Repo.all(query)
  end

  def get_events(user_id, start_datetime, limit) do
    end_datetime = DateTime.add(start_datetime, 86400) # add 24 hours in seconds
    get_events(user_id, start_datetime, end_datetime, limit)
  end

  def get_events(user_id, limit) do
    query = from(e in AiAssistant.NoteSpace.Event,
          where: e.user_id == ^user_id,
          order_by: [desc: e.updated_at],
          limit: ^limit)

    Repo.all(query)
  end
end
