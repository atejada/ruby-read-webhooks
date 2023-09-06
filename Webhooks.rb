# Load gems
require 'nylas'
require 'sinatra'
require "sinatra/config_file"

port = ENV["PORT"] || "4567"
configure { 
  set :server, :puma
  set :bind, '0.0.0.0'
  set :port, port
}

# We display the database content
get '/' do
    if params.include? "challenge"
	    "#{params['challenge']}"
   end
end
