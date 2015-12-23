class AddIsRealToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_real, :boolean
  end
end
