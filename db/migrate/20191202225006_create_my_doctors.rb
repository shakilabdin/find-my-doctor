class CreateMyDoctors < ActiveRecord::Migration[5.2]
  def change
    create_table :my_doctors do |t|
      t.integer :user_id
      t.integer :doctor_id
    end
  end
end
