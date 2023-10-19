defmodule AiAssistant.Repo.Migrations.CreateUserTzEstimate do
  use Ecto.Migration

  def change do
    create table(:user_time_zones) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :time_diff_minutes, :integer, null: false # time difference in minutes

      timestamps()
    end

    create unique_index(:user_time_zones, [:user_id])
  end
end
