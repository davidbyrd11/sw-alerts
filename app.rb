require 'rubygems'
require 'sinatra'
require 'twilio-ruby'
require 'mongo'
require 'json'
require './lib/SMSUser'

bad_command_msg = "Erg. I don't know what to do with that. Text HELP for help."

get '/' do
  "Stop looking at me."
end

#
# call
#
get %r{/call/?} do
  headers['Content-Type'] = 'text/xml; charset=utf8'
  xmldoc = Twilio::TwiML::Response.new do |r|
    r.Say 'Welcome to Startup Week! Too get alerts, please text your name to 7 0 3, 34, T X T, S W,  Thats 7 0 3, 3 4 8, 9 8 7 9'
  end
  xmldoc.text
end

#
# sms
#
get %r{/sms/?} do
  
  response = nil
  
  phone = params['From'] == nil ? '' : params['From']
  msg = params['Body'] == nil ? '' : params['Body'].strip
  
  user = SMSUser.new phone
  
  case msg
  
  # show help
  when /^help$/i
    response = user.get_help

  # unsubscribe
  when /^unsubscribe$/i
    response = user.unsubscribe
  
  # confirm
  when /^yes$/i
    # broadcast (admin only)
    if user.is_admin && user.has_broadcast_pending then
      response = user.confirm_broadcast
    # subscribe
    else
      response = user.confirm_subscribe
    end
    
  # broadcast message (admin only)
  when /^B:/i
    response = user.broadcast msg[2..-1] if user.is_admin
    
  # attempt subscribe
  else
    response = user.subscribe msg
    
  end
  
  # respond
  if response != nil then
    headers['Content-Type'] = 'text/xml; charset=utf8'
    xmldoc = Twilio::TwiML::Response.new do |r|
      r.Sms response
    end
    xmldoc.text
  end
end


not_found do
  status 404
  "um... no."
end
