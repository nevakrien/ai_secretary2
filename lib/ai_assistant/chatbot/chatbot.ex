defmodule AiAssistant.Chatbot do
  @moduledoc """
  The Chatbot context.
  """

  import Ecto.Query, warn: false
  alias AiAssistant.Repo

  alias AiAssistant.Chatbot.Conversation
  alias AiAssistant.Chatbot.Message 
  alias AiAssistant.Chatbot.AiService

  def generate_response(conversation, messages) do
  last_five_messages =
    Enum.slice(messages, 0..4)
    |> Enum.map(fn %{role: role, content: content} ->
      %{"role" => role, "content" => content}
    end)
    |> Enum.reverse()

  create_message(conversation, AiService.call(last_five_messages))
end

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