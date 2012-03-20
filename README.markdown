Startup Week SMS Alerts
=======================

This handles SMS alerts for NYU Startup Week. Admins can broadcast to subscribers by prepending a message with "B:"

A local_settings.rb file is required in the root with the following globals defined:

* $account_sid (Twilio account SID)
* $auth_token (Twilio auth token)
* $app_sid (Twilio app SID)
* $sw_alerts_number (phone number associated with the Twilio app)
* $admins (array of phone numbers who are admins)


Powered by [Twilio](http://twilio.com).
