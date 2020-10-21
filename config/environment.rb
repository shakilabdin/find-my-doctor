require 'bundler'
Bundler.require
require 'dotenv/load'
ActiveRecord::Base.logger = nil


PASTEL = Pastel.new


ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3', 
  database: 'db/find_my_doctor.db'
  )
require_all 'lib'
