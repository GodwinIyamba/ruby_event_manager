require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, "0")[0..4]
end

def legislator_by_zipcode(zipcode)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        civic_info.representative_info_by_address(
            address: zipcode,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue
        "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
    end
    
end

def thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')
    file_name = "output/file_#{id}.html"
    File.open(file_name, 'w') {|file| file.puts(form_letter)}
end

def clean_phone(phone)
    phone = phone.to_s.gsub(/[^0-9]/, '')

    if phone.length == 11 && phone[0] == "1"
        phone = phone[1..10]
        phone = "#{phone[0..2]}-#{phone[3..5]}-#{phone[6..9]}"
    elsif phone.length == 11 && phone[0] != "1"
        phone = "Invalid Phone Number"
    elsif phone.length == 10
        phone = "#{phone[0..2]}-#{phone[3..5]}-#{phone[6..9]}"
    else 
        phone = "Invalid Phone Number"
    end
end

def registration_hour(reg_date)
    format_date = DateTime.strptime(reg_date, '%m/%d/%y %k:%M')
end

def max_no_hours(array_hours, hash_hours, hash_days)
    interim_hour = Array.new
    interim_day = Array.new

    array_hours.filter do |hour|
        interim_hour.push(hour.first)
        interim_day.push(hour.last)
    end

    interim_hour.filter do |hour|
        hash_hours[hour] = interim_hour.count(hour)
    end

    interim_day.filter do |day|
        hash_days[day] = interim_day.count(day)
    end
end

def max_hours(hash_hours, hash_days, max_hour, max_day)
    hash_hours.each do |k, v| 
        max_hour.push(k) if v == hash_hours.values.max
    end 

    hash_days.each do |k, v| 
        max_day.push(k) if v == hash_days.values.max
    end 
end

puts "Event Manager Initialized"

contents = CSV.open(
    '../event_attendees.csv',
    headers: true,
    header_converters: :symbol
)

template_file = File.read('form_letter.erb')
erb_file = ERB.new(template_file)

hour_day_index = Array.new
hours_key_value = Hash.new
days_key_value = Hash.new
hours_of_day = Array.new
days_of_week = Array.new
max_day = Array.new

days = {0=>"sunday",1=>"monday",2=>"tuesday",3=>"wednesday",4=>"thursday",5=>"friday",6=>"saturday"}

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    reg_date = row[:regdate]
    
    zipcode = clean_zipcode(row[:zipcode])
    phone = clean_phone(row[:homephone])
    
    legislators = legislator_by_zipcode(zipcode)
    
    hour_of_day = registration_hour(reg_date).hour
    day_of_week = registration_hour(reg_date).wday
    
    hour_day_index.push([hour_of_day, day_of_week])

    form_letter = erb_file.result(binding)
    thank_you_letter(id, form_letter)
end

max_no_hours(hour_day_index, hours_key_value, days_key_value)

max_hours(hours_key_value, days_key_value, hours_of_day, days_of_week)

days_of_week = days_of_week.map do |day|
    days.each do |k, v|
         max_day.push(v) if k == day
    end
end

hours_of_day = hours_of_day.join(", ")
max_day = max_day.join(", ").capitalize

puts "Hour of day for maximum registeration: #{hours_of_day}"
puts "Day of the week with maximum registeration: #{max_day}"
