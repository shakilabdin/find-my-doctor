class AddRatingsToDoctors < ActiveRecord::Migration[5.2]
  def change
    add_column :doctors, :rating, :float
  end
end
