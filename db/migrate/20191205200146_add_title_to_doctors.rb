class AddTitleToDoctors < ActiveRecord::Migration[5.2]
  def change
    add_column :doctors, :title, :string
  end
end
