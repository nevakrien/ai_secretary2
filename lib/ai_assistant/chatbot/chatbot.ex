defmodule AiAssistant.Chatbot do
  @moduledoc """
  The Chatbot context.
  """

  import Ecto.Query, warn: false
  alias AiAssistant.Repo

  alias AiAssistant.Chatbot.Conversation
  alias AiAssistant.Chatbot.Message 

  def list_chatbot_conversations do
    Repo.all(Conversation)
  end 

  def create_conversation(attrs \\ %{}) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
  end

  def update_conversation(%Conversation{} = conversation, attrs) do
    conversation
    |> Conversation.changeset(attrs)
    |> Repo.update()
  end

  def create_message(conversation, attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:conversation, conversation)
    |> Repo.insert()
  end

  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message,    attrs)
  end
end