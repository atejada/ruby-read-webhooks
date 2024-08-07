# Load gems
require 'nylas'
require 'sinatra'
require "sinatra/config_file"

webhook = Data.define(:id, :time, :bounce_reason, :bounce_address)
#webhook = Data.define(:id, :date, :title, :description, :participants, :status)
webhooks = Array.new

get '/webhook' do
    if params.include? "challenge"
	    "#{params['challenge']}"
   end
end

post '/webhook' do
    puts "Calling the Webhook"	
# We need to verify that the signature comes from Nylas
    is_genuine = verify_signature(message = request.body.read, key = ENV['CLIENT_SECRET'], signature = request.env['HTTP_X_NYLAS_SIGNATURE'])
    if !is_genuine
        status 401
        "Signature verification failed!"
    end

    puts("Webhook verified")

# Initialize Nylas client
    nylas = Nylas::Client.new(
	    api_key: ENV["V3_TOKEN"]
    )
	
# Query parameters
#query_params = {
#    calendar_id: ENV["CALENDAR_ID"]
#}	
	
# We read the webhook information and store it on the data class
    request.body.rewind
    model = JSON.parse(request.body.read)
    puts(model)
    # Bounce detection starts
    puts("Bounce should start")
    hook = webhook.new(model["data"]["id"], model["data"]["time"], model["data"]["object"]["bounce_reason"], model["data"]["object"]["bounce_address"])
    webhooks.append(hook)
    # Bounce detection ends

    #if model["data"]["object"]["calendar_id"] == ENV["CALENDAR_ID"]
    #    event, _request_id = nylas.events.find(identifier: ENV["GRANT_ID"], object_id: model["data"]["object"]["id"], query_params: query_params) 
    #    participants = ""
    #    event_date = ""
    #    event[:participants].each do |elem|
    #        participants += "#{elem[:email]}; "
    #    end
    
    #    case event[:when][:object]
    #        when 'timespan'
    #        start_time = Time.at(event[:when][:start_time]).strftime('%m-%d-%Y %H:%M:%S')
    #        end_time = Time.at(event[:when][:end_time]).strftime('%m-%d-%Y %H:%M:%S')
    #        event_date = "#{start_time} to #{end_time}"
    #      when 'datespan'
    #          start_time = event[:when][:start_date].strftime('%m-%d-%Y')
    #          end_time = event[:when][:end_date].strftime('%m-%d-%Y')
    #          event_date = "#{start_time} to: #{end_time}"	    
    #      when 'date'
    #          start_time = event[:when][:date].strftime('%m-%d-%Y') 
    #          event_date = "#{start_time} "
    #      end
    #    hook = webhook.new(event[:id], event_date, event[:title], event[:description], participants, event[:status])
    #    webhooks.append(hook)
    #end
	status 200
	"Webhook received"	
end

get '/' do
    erb :main, :locals => {:webhooks => webhooks}
end

# We generate a signature with our client secret and compare it with the one from Nylas
def verify_signature(message, key, signature)
	digest = OpenSSL::Digest.new('sha256')
	digest = OpenSSL::HMAC.hexdigest(digest, key, message)
	secure_compare(digest, signature)
end

# We compare the keys to see if they are the same
def secure_compare(a, b)
	return false if a.empty? || b.empty? || a.bytesize != b.bytesize
	l = a.unpack "C#{a.bytesize}"

	res = 0
	b.each_byte { |byte| res |= byte ^ l.shift }
	res == 0
end
