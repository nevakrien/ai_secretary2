defmodule AiAssistant.Repo.Migrations.CreateChatbotConversations do
  use Ecto.Migration

  def change do
    create table(:chatbot_conversations) do
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:chatbot_conversations, [:user_id, :inserted_at])
    create unique_index(:chatbot_conversations, [:user_id, :updated_at])
  end
end
