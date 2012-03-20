require './app.rb'

set :environment, ENV['RACK_ENV'].to_sym
set :app_file, 'app.rb'
enable :logging, :dump_errors, :raise_errors
disable :run

run Sinatra::Application
