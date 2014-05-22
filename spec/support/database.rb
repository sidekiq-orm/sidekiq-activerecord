db_config = {:adapter => 'sqlite3', :database => ':memory:'}
ActiveRecord::Base.establish_connection(db_config)
connection = ActiveRecord::Base.connection

connection.create_table :users, force: true do |t|
  t.string :name
  t.string :email
  t.string :status
  t.timestamps
end