class CreateDoctors < ActiveRecord::Migration[5.2]
  def change
    create_table :doctors do |t|
      t.string :name
      t.string :phone
      t.string :address
      t.string :specialties
      t.string :insurances
    end
  end
end
