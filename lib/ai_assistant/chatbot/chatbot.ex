defmodule AiAssistant.Chatbot do
  @moduledoc """
  The Chatbot context.
  """

  import Ecto.Query, warn: false
  alias AiAssistant.Repo

  alias AiAssistant.Chatbot.Conversation
  alias AiAssistant.Chatbot.DataHandling
  alias AiAssistant.Chatbot.Message 
  alias AiAssistant.Chatbot.AiService

  def generate_response(conversation, messages) do
    last_messages =
      Enum.slice(messages, 0..3)
      |> Enum.map(fn %{role: role, content: content} ->
        %{"role" => role, "content" => content}
      end)
      |> Enum.reverse()

    # need to integrate
    task_details = DataHandling.fetch_task_details(conversation.user_id) 
    IO.inspect(task_details, label: "Fetched task details")

    create_message(conversation, AiService.call(last_messages,task_details))
  end

  def get_conversation(user_id) do
    # Trying to get the most recent conversation
    conversation = 
      Repo.one(
        from(c in Conversation,
          where: c.user_id == ^user_id,
          order_by: [desc: c.inserted_at],
          limit: 1
        )
      )

    # If there's no existing conversation, create a new one
    case conversation do
      nil ->
        {:ok, new_conversation} = create_conversation(%{user_id: user_id})
        new_conversation
      _ ->
        conversation
    end
  end

  def list_messages_for_conversations(conversation_id) do
    from(m in Message,
      where: m.conversation_id == ^conversation_id,
      order_by: [desc: m.inserted_at],
      limit: 5
    )
    |> Repo.all()
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