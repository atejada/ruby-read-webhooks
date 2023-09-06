# Load gems
require 'nylas'
require 'sinatra'
require "sinatra/config_file"

# We display the database content
get '/' do
    if params.include? "challenge"
	    "#{params['challenge']}"
   end
end
