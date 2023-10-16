defmodule AiAssistant.Repo.Migrations.AddUpdatedAtIndexToEvents do
  use Ecto.Migration

  def change do
    create index(:events, [:user_id,:updated_at])
    create index(:events, [:user_id,:inserted_at])
  end
end
