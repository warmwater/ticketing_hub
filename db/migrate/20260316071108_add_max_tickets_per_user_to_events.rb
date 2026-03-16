class AddMaxTicketsPerUserToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :max_tickets_per_user, :integer
  end
end
