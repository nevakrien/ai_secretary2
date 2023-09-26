defmodule AiAssistant.Repo.Migrations.CreateChatbotConversations do
  use Ecto.Migration

  def change do
    create table(:chatbot_conversations) do

      timestamps()
    end
  end
end
