
require 'yaml'
require 'active_record'

current_dir = File.expand_path(File.dirname(__FILE__))
app_root = File.join(current_dir, "../../")
conn_spec = YAML.load_file(File.join(app_root, "config", "database.yml"))

ENV["RAILS_ENV"] ||= "production"

ActiveRecord::Base.establish_connection(conn_spec[ENV["RAILS_ENV"]])

$:.unshift File.join(app_root, "app", "models")
%w[task].each do |model|
  require model
end
