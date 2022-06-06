# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

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
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
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

def clean_phone_number(phone_number)
  phone_number = phone_number.tr(' .//()-', '')
  phone_number = phone_number[1..10] if phone_number.length == 11 && phone_number[0] == 1
  phone_number = '' unless phone_number.length.eql? 10
  phone_number.rjust(10, '0')
end

def extract_hour_index(string)
  Time.strptime(string, '%m/%d/%y %H:%M').hour
end

def display_peak_hour(hour_array)
  peak_registration_hour = hour_array.max
  peak_hour_array = []

  hour_array.each_with_index do |hour_count, hour|
    peak_hour_array.push("Hour #{hour}:00") if hour_count == peak_registration_hour
  end

  puts "The peak registration hours are #{peak_hour_array.join(', ')}"
end

def extract_day_index(string)
  Date.strptime(string, '%m/%d/%y %H:%M').wday
end

def display_peak_day(day_array)
  peak_registration_day = day_array.max
  peak_day_array = []

  day_array.each_with_index do |day_count, day_index|
    peak_day_array.push(convert_index_to_day(day_index)) if day_count == peak_registration_day
  end

  puts "The peak registration day is #{peak_day_array.join(', ')}"
end

def convert_index_to_day(index)
  case index
  when 0
    "Sunday"
  when 1
    "Monday"
  when 2
    "Tuesday"
  when 3
    "Wednesday"
  when 4
    "Thursday"
  when 5
    "Friday"
  when 6
    "Saturday"
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hour_index_array = Array.new(24, 0)
day_index_array = Array.new(7, 0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  homephone = clean_phone_number(row[:homephone])
  hour_index_array[extract_hour_index(row[:regdate])] += 1
  day_index_array[extract_day_index(row[:regdate])] += 1
  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

display_peak_hour(hour_index_array)
display_peak_day(day_index_array)
