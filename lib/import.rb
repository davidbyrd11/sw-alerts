require './SMSUser'

# imports batches of users from a file or user list specified in the command line
#
# file format:       NAME,PHONE \n NAME,PHONE \n ...
# user list format:  NAME,PHONE | NAME,PHONE | ...
#
# usage examples:
#   ruby import.rb f=newusers
#   ruby import.rb u="El Guapo, 2125551212 | Slim, 8005551010"


field_del = ','
err = false
list = nil

if !ARGV[0]
	puts 'missing arguments'
	err = true

# file
elsif ARGV[0][0] == 'f'
	file = ARGV[0][2..-1]
	begin
		File.open(file) do |f|
			list = f.gets(nil)
		end
	rescue Errno::ENOENT
		puts "can't find file: #{file}"
		err = true
	end
	
	line_del = "\n"
	
# user list
elsif ARGV[0][0] == 'u'
	list = ARGV[0][2..-1]
	line_del = '|'
	
# err
else
	puts 'invalid arguments'
	err = true
end

# add users
if !err
	# create admin user to add everyone
	admin = SMSUser.new('+18582480841')
	
	users = list.split line_del
	users.each do |u|
		name,phone = u.split field_del
		
		# ensure proper number format
		phone.gsub! /[^0-9]/, ''
		phone = phone[-10..-1]
		
		if phone.length == 10
			puts admin.admin_subscribe(name, phone)
		else
			puts "invalid phone number (#{phone}) for #{name}"
		end
	end
end
