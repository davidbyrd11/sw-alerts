require 'rubygems'
require 'mongo'
require 'twilio-ruby'
require './local_settings'

#
# handles interaction with an SMS user
#
class SMSUser
  
  def initialize(phone)
    
    # messages
    @general_error = "Erg. I don't know what to do with that. Text HELP for help."
    @help_msg = "Prizes, surprises, and cupcakes! Oh, my! Text your name to subscribe to Startup Week alerts! Text UNSUBSCRIBE to unsubscribe."
    @subscribe_msg = "Hello! You are subscribing to Startup Week alerts as \"%s\". If your name is correct, text YES to confirm. If not, text your name again."
    @subscribe_err = "You are already subscribed to Startup Week alerts. Text HELP for help."
    @confirm_msg = "Welcome, %s! You are now subscribed to Startup Week alerts. Text UNSUBSCRIBE to unsubscribe."
    @confirm_err = @general_error
    @unsubscribe_msg = "G'bye! You have unsubscribed from Startup Week alerts. Text your name to re-subscribe."
    @unsubscribe_err = "You are not subscribed. Text HELP for help."
    @broadcast_msg = "You are about to broadcast your message to all subscribers. Text YES to confirm."
    @confirm_broadcast_msg = "Your message has been sent."
    # end messages
    
    @phone = phone
    
    @db_name = 'sw_alerts'
    @users_coll = 'users'
    @users_uc_coll = 'users_uc' # unconfirmed users queue
    @broadcast_queue = 'broadcast_queue'

    @db = Mongo::Connection.new.db(@db_name)
    #TODO verify db connection
  end
  
  #
  # helper: verifies the user is subscribed
  # (unconfirmed=true searches unconfirmed users)
  #
  def is_subscribed(unconfirmed=false)
    coll = unconfirmed===true ? @db[@users_uc_coll] : @db[@users_coll]
    if coll.find_one('phone' => @phone) == nil then
      false
    else
      true
    end
  end
  
  #
  # helper: verifies whether the user is admin
  #
  def is_admin
    if $admins.index(@phone) === nil then
      false
    else
      true
    end
  end
  
  #
  # helper: verifies whether user has a broadcast pending
  #
  def has_broadcast_pending
    if @db[@broadcast_queue].find_one({'admin_phone' => @phone}) == nil then
      false
    else
      true
    end
  end
  
  #
  # returns the user specified by the given phone number
  # (unconfirmed=true pulls from unconfirmed users queue)
  #
  def get_user(phone, unconfirmed=false)
    coll = unconfirmed===true ? @db[@users_uc_coll] : @db[@users_coll]
    coll.find_one({'phone' => phone})
  end
  
  #
  # returns the help msg
  #
  def get_help
    @help_msg
  end
  
  #
  # subscribes a new user (UNCONFIRMED)
  #
  def subscribe(name)
    return @subscribe_err if self.is_subscribed # must not already be subscribed
    
    @db[@users_uc_coll].remove({'phone' => @phone})
    @db[@users_uc_coll].insert({
      'name' => name,
      'phone' => @phone
    })
    sprintf(@subscribe_msg, name)
  end
  
  #
  # confirms new user subscription
  #
  def confirm_subscribe
    return @subscribe_err if self.is_subscribed # must not already be subscribed
    return @confirm_err if !self.is_subscribed(true) # must be in queue
    
    user = self.get_user(@phone, true)
    @db[@users_coll].insert({
      'name' => user['name'],
      'phone' => @phone
    })
    @db[@users_uc_coll].remove({'phone' => @phone})
    sprintf(@confirm_msg, user['name'])
  end
  
  #
  # unsubscribes the user
  #
  def unsubscribe
    return @unsubscribe_err if !self.is_subscribed # must be subscribed
    
    @db[@users_coll].remove({'phone' => @phone})
    @unsubscribe_msg
  end
  
  #
  # queues up SMS broadcast
  #
  def broadcast(msg)
    return nil if !self.is_admin # must be admin
    
    @db[@broadcast_queue].insert({
      'admin_phone' => @phone,
      'message' => msg
    })
    @broadcast_msg
  end
  
  #
  # confirms and sends SMS broadcast
  #
  def confirm_broadcast
    return nil if !self.is_admin || !self.has_broadcast_pending # must be admin and have message in queue
    
    # retrieve message from queue
    broadcast_msg = @db[@broadcast_queue].find_one({'admin_phone' => @phone})
    
    # send it
    client = Twilio::REST::Client.new $account_sid, $auth_token
    users = @db[@users_coll].find
    users.each do |user|
      # puts "SEND! #{user['name']}, #{user['phone']}" #TESTING
      client.account.sms.messages.create(
        :from => $sw_alerts_number,
        :to => user['phone'],
        :body => broadcast_msg
      )
    end
    
    @db[@broadcast_queue].remove({'admin_phone' => @phone})
    @confirm_broadcast_msg
  end
  
end