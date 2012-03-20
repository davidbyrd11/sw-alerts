require 'rubygems'
require 'sinatra'
require 'twilio-ruby'
#require 'bson_ext'
require 'mongo'
require 'json'
require './lib/SMSUser'

get '/' do
  "Stop looking at me."
end

#
# call
#
post %r{/call/?} do
  headers['Content-Type'] = 'text/xml; charset=utf8'
  xmldoc = Twilio::TwiML::Response.new do |r|
    r.Say 'Welcome to Startup Week! Too get alerts, please text your name to 7 0 3, 34, T X T, S W, , Thats 7 0 3, 34, T X T, S W, , That number again is 7 0 3, 3 4 8, 9 8 7 9'
  end
  xmldoc.text
end

#
# sms
#
post %r{/sms/?} do
  
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
    if user.is_admin then
      response = user.confirm_broadcast
    # subscribe
    else
      response = user.confirm_subscribe
    end
    
  # broadcast message (admin only)
  when /^B:/i
    response = user.broadcast msg[2..-1].strip if user.is_admin
  
  # subscribe new user (admin only)
  when /^S:/i
    msg = msg[2..-1].split %r{,\s*}
    if msg.count == 2 then
      response = user.admin_subscribe msg[0].strip, msg[1].strip
    else
      response = user.general_err
    end
  
  # unsubscribe user (admin only)
  when /^US:/i
    response = user.admin_unsubscribe msg[3..-1].strip

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
  "negatory, good buddy."
end
