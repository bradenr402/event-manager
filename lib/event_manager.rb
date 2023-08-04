require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(phone)
  phone.gsub!(/[^\d]/,'')
  if phone.length == 10
    phone
  elsif phone.length == 11 && phone[0] == '1'
    phone[1..10]
  else
    "invalid number"
  end
end

def most_registered_hours()

end

def date_to_object(date_time)
  DateTime.strptime(date_time, "%m/%d/%Y %H:%M")
end

def most_frequent(array)
  frequency_count = Hash.new(0)
  array.each { |item| frequency_count[item] += 1 }
  top_three = frequency_count.sort_by { |item, frequency| frequency }.reverse.to_a.first(3)
  top_three.map { |pair| pair[0] }
end

def format_times(times)
  times.map.with_index do |time, index|
    if index == 2
      "and #{time}:00."
    else
      "#{time}:00"
    end
  end.join(', ')
end

def format_days(days)
  days_of_week = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
  days.map.with_index do |day, index|
    if index == 2
      "and #{days_of_week[day]}."
    else
      "#{days_of_week[day]}"
    end
  end.join(', ')
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter



hours_array = []
days_array = []


contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_numbers(row[:homephone])
  reg_date = date_to_object(row[:regdate])
  hours_array.push(reg_date.hour)
  days_array.push(reg_date.wday)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end

puts "The most common hours of the day people registered are #{format_times(most_frequent(hours_array))}"
puts "The most common days of the week people registered are #{format_days(most_frequent(days_array))}"
