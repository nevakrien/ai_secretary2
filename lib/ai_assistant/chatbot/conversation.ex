defmodule AiAssistant.Chatbot.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chatbot_conversations" do

    belongs_to :user, AiAssistant.Accounts.User

    has_many :messages, AiAssistant.Chatbot.Message, preload_order: [desc: :inserted_at]
    timestamps()
  end

  @doc false
  def changeset(conversation, _attrs) do
    conversation
    #|> cast(attrs, [:resolved_at])
  end
end
  