require "time"


class BusinessHour

	

	def initialize(start_time, end_time)
		@start_time = railway_format(start_time)
		@end_time = railway_format(end_time)

		begin
			if Time.parse(@end_time) <= Time.parse(@start_time)
				raise Exception.new("Error in new: EndTime is Before is StartTime")
			end
		rescue Exception => e
			puts e.message
			exit
		end

		@weeks=[:sun, :mon, :tue, :wed, :thu, :fri, :sat]
		@updatedDays = {} #hashes with start adn end times (key: day of week)
		@updatedDates = [] #array of hashes with date, start and end times 
		@closedDates=[] #array of closed dates
		@closedDays=[]  #array of closed days of the week


	end

	def update(day, start_time, end_time)
		begin
			if Time.parse(railway_format(end_time)) <= Time.parse(railway_format(start_time))
				raise Exception.new("Error in Update : EndTime is Before is StartTime")
			end
		rescue Exception => e
			puts e.message
			exit
		end
		
		if day.is_a? Symbol
			@updatedDays[day] = {start_time: railway_format(start_time), end_time: railway_format(end_time)}
		else
			@updatedDates.push({date: day, start_time: railway_format(start_time), end_time: railway_format(end_time)})
		end

	end

	def closed(*dates)
		dates.each { |date|
			if date.is_a? Symbol
				@closedDays.push(date)
			else
				@closedDates.push(date)
			end
		}

	end

	def calculate_deadline(interval, start)

		given_date = start.scan(/[a-zA-Z]{3}[ ][0-9]{1,2}[,][ ][0-9]{4}/)[0]
		given_start_time = railway_format(start.scan(/[0-9]{1,2}[:][0-9]{2}[ ][AP][M]/)[0])
		given_start_time_object = Time.parse(given_date + " " + given_start_time)

		# if given start day is closed day, then it moves to next working day
		if(is_closed(given_start_time_object))
			given_start_time_object = push_to_next_working_day(given_start_time_object)
			given_date = given_start_time_object.strftime("%b %d, %Y")
		end

		working_time = get_working_time(given_date)

		# start and end time of given day
		start_time_object = Time.parse(given_date + " " + working_time[:start_time])
		end_time_object = Time.parse(given_date + " " + working_time[:end_time])

		if(given_start_time_object < start_time_object)
			given_start_time_object = start_time_object
		end

		expected_delivery_time_object = given_start_time_object + interval

		#if expected time exceeds end time, it moves the remaining time to next working day
		if expected_delivery_time_object > end_time_object
			time_remaining = expected_delivery_time_object - end_time_object
			expected_delivery_time_object = push_to_next_working_day(expected_delivery_time_object, time_remaining)
			
			expected_delivery_date = expected_delivery_time_object.strftime("%b %d, %Y")
			working_time = get_working_time(expected_delivery_date)
			start_time_object = Time.parse(expected_delivery_date + " " + working_time[:start_time])
			end_time_object = Time.parse(expected_delivery_date + " " + working_time[:end_time])

			expected_delivery_time_object = start_time_object + time_remaining
		end

		puts frame_output_time(expected_delivery_time_object)

	end

	private
	def frame_output_time(time_object)
		time_object.strftime("%a %b %d %H:%M:%S %Y")
	end

	def push_to_next_working_day(time_object, time_remaining=0)
		flag = true
		time_object =Time.new(time_object.year,time_object.month,time_object.day,0,0,0,"+05:30") + (24*60*60)
		while is_closed(time_object)
			time_object =Time.new(time_object.year,time_object.month,time_object.day,0,0,0,"+05:30") + (24*60*60)
		end
		time_object

	end
	
	def is_closed(date_object)
		#day of the week
		flag =  false
		@closedDays.each{ |closedDay|
			if @weeks[date_object.wday] == closedDay
				flag = true
				break
			end
		}
		#date
		if flag !=true
			@closedDates.each{ |closedDate|
				closedDateObject = Time.parse(closedDate)

				if closedDateObject == date_object
					flag = true
					break
				end
			}
		end
		flag
	end
	

	def get_working_time(date_string)
		flag = false
		#day of the week
		@updatedDates.each{ |updatedDate|
			if updatedDate[:date] == date_string
				flag = true
				return {start_time: updatedDate[:start_time], end_time: updatedDate[:end_time]}
				break
			end
		}
		tempTime = Time.parse(date_string)
		#date
		if flag != true
			@updatedDays.each{ |day, updatedDate|
				if @weeks[tempTime.wday] == day
					flag = true
					return updatedDate
					break
				end
			}
		end
		if flag != true
			return {start_time: @start_time, end_time: @end_time}
		end
	end

	def railway_format(time)
		Time.strptime(time,"%l:%M %P").strftime("%k:%M")
	end


end

class Main
	def self.main
		hours = BusinessHour.new("9:00 AM", "3:00 PM")

		hours.update :fri, "10:00 AM", "5:00 PM"
		hours.update "Dec 24, 2010", "8:00 AM", "1:00 PM"
		hours.closed :sun, :wed, "Dec 25, 2010"

		hours.calculate_deadline(2*60*60, "Jun 7, 2010 9:10 AM")
		hours.calculate_deadline(15*60, "Jun 8, 2010 2:48 PM")
		hours.calculate_deadline(7*60*60, "Dec 24, 2010 6:45 AM")


	end
end

Main.main
