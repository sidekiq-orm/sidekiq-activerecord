source 'https://rubygems.org'
gemspec



platforms :ruby do
  gem 'sqlite3'
end

platform :mri_20, :mri_21 do
  gem 'byebug'
end

platforms :jruby do
  gem 'activerecord-jdbcsqlite3-adapter'
end
