defmodule AiAssistant.Chatbot.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chatbot_conversations" do

    belongs_to :user, AiAssistant.Accounts.User

    has_many :messages, AiAssistant.Chatbot.Message, preload_order: [desc: :inserted_at]
    timestamps()
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:user_id])
    |> validate_required([:user_id])
  end
end
  