require 'mechanize'
require 'awesome_print'
require 'nokogiri'

@private_availability = {}
@female_availability = {}
@male_availability = {}
@coed_availability = {}

def load_availability
  dates = [Date.today.next_day, Date.today.next_day(19), Date.today.next_day(33), Date.today.next_day(47), Date.today.next_day(61)]
  dates.each do |date|
    avail_table = get_table(date)
    parse_table(avail_table)
    wait_random
  end
end

def wait_random
  random_sec = rand(2..5)
  puts "sleeping #{random_sec}"
  sleep(random_sec)
end

def get_table(date)
  @agent ||= Mechanize.new
  check_in_month = date.month.to_s.length > 1 ? date.month.to_s : '0' + date.month.to_s
  check_in_day = date.day.to_s.length > 1 ? date.day.to_s : '0' + date.day.to_s
  check_in_year = date.year.to_s
  check_out_month = date.next_day.month.to_s.length > 1 ? date.next_day.month.to_s : '0' + date.next_day.month.to_s
  check_out_day = date.next_day.day.to_s.length > 1 ? date.next_day.day.to_s : '0' + date.next_day.day.to_s
  check_out_year = date.next_day.year.to_s

  # Load availability form
  reservation_home = @agent.get('https://www.whistler.hihostels.ca/iqreservations/asp/IQHome.asp')

  # Click the date selection link
  date_selection_page = @agent.click(reservation_home.link_with(:text => /Make a reservation/))

  # Submit the availability form
  results_page = date_selection_page.form_with(:action => 'AgentLogin.asp') do |f|
    f.CheckInMonth = check_in_month
    f.CheckInDay = check_in_day
    f.CheckInYear = check_in_year
    f.CheckOutMonth = check_out_month
    f.CheckOutDay = check_out_day
    f.CheckOutYear = check_out_year
  end.click_button
  
  doc = Nokogiri::HTML(results_page.parser.to_s.force_encoding("UTF-8"))

  table_array = doc.css("#availTbl").map do |element|
    element.inner_text
  end
  puts "got table for #{date}"
  table_array
end

def parse_table(table)
  availability_table = table[0].split("\n")

  date_index = availability_table[5][0..-2].gsub(/[A-Z][a-z]*/,'').strip.split(' ').collect { |date| Date.today.year.to_s + '/' + date }
  private_room = availability_table.slice(10..23)
  female_dorm = availability_table.slice(27..40)
  male_dorm = availability_table.slice(44..57)
  coed_dorm = availability_table.slice(61..74)

  @private_availability.merge!(Hash[date_index.zip(private_room)])
  @female_availability.merge!(Hash[date_index.zip(female_dorm)])
  @male_availability.merge!(Hash[date_index.zip(male_dorm)])
  @coed_availability.merge!(Hash[date_index.zip(coed_dorm)])
  puts "parsed table for dates #{date_index[0]} to #{date_index.last}"
end

load_availability

ap @coed_availability

