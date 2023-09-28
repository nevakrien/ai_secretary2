defmodule AiAssistant.AiAssistant.Chatbot.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chatbot_conversations" do
    field :resolved_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:resolved_at])
    |> validate_required([:resolved_at])
  end
end
