defmodule AiAssistant.Repo.Migrations.CreateChatbotMessages do
  use Ecto.Migration

  def change do
    create table(:chatbot_messages) do
      add :content, :text
      add :role, :string
      add :conversation_id, references(:chatbot_conversations, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:chatbot_messages, [:conversation_id, :inserted_at])
  end
end
