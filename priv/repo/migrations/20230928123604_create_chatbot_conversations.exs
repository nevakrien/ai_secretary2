defmodule AiAssistant.Repo.Migrations.CreateChatbotConversations do
  use Ecto.Migration

  def change do
    create table(:chatbot_conversations) do
      #add :resolved_at, :naive_datetime

      timestamps()
    end
  end
end
