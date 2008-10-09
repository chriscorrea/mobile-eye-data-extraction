require 'rubygems'
#require 'rvideo'
require 'csv'

if ARGV.size == 1
  puts 'Data: ' + ARGV[0].to_s
  data_file = ARGV[0].to_s
  video_file = nil
elsif ARGV.size == 2
  puts 'Data: ' + ARGV[0].to_s
  puts 'Video: ' + ARGV[0].to_s
    data_file = ARGV[0].to_s
  video_file = ARGV[1].to_s
else
  raise "Syntax: extract.rb <datafile> <videofile>" if ARGV.size < 1  
end

class Fixation
  attr_accessor :x, :y, :start, :duration, :id
  
  #a new fixation requires x,y coordinates and a start time
  def initialize(x,y,start)  
       @x = x  
       @y = y
       @start = start
       @duration = 1  
  end
  
  def formatted_timestamp
    @fields = @start.split(/\./) 
    return @fields[0] + '.' + (@fields[1].to_i * 10).to_s
  end
end

#SET GLOBAL PREF (these should be customizable eventually)
  #max allowable square of x coordinate difference between two frames of a single fixation
  x_squared = 9
  #max allowable square of y coordinate difference between two frames of a single fixation
  y_squared = 9
  #min consecutive frames to be saved as a valid fixation
  required_frames = 3
  #transform fraction of a second
  sec_transform = 100
  
puts 'Mobile Eye Data Extraction'
puts 'By Christopher Correa'
puts 'Version 0.1 (October 2008)'
puts '-------'

#Intialize the results array (where we will store info about valid fixations)
results = Array.new(0)

#Load the csv data file specified at command line
data = CSV.read(data_file)

data.each do |d|
  
  #if there is not an old fixation and we start another potential fixation
  if @f.nil? 
    @f = Fixation.new(-2000.0,-2000.0,0)    
  end
  
  if d[2].to_i > 0 && d[2].to_i < 1000 && d[3].to_i > -1000 && d[3].to_i < 1000 && (  ((d[2].to_f-@f.x)*(d[2].to_f-@f.x))>x_squared ||  ((d[3].to_f-@f.y)*(d[3].to_f-@f.y))>y_squared )
      #if there is an old fixation and we start another potential fixation
      
      if(@f.duration>=required_frames)
        results.push([results.size,@f.formatted_timestamp,@f.duration])
      end
      
      #Create a new eye event (a potential fixations)
      @f = Fixation.new(d[2].to_f,d[3].to_f,d[0].to_s)
      
  elsif d[2].to_i > 0 && d[2].to_i < 1000 && d[3].to_i > -1000 && d[3].to_i < 1000
      
      #These is valid data here, so we are continuing an existing fixation and will increase duration
      @f.duration = @f.duration + 1
  else
    #No good data here (missing or not valid)!
    
    if(@f.duration>=required_frames)
      #If the old fixation is valid, save it to results array
      results.push([results.size,@f.formatted_timestamp,@f.duration])
    end
    
    #Now just initiate a new dummy eye event and move on to next row
    @f = Fixation.new(-2000.0,-2000.0,d[0].to_s)
    #@f.x = -2000.1
    #@f.y = -2000.1
  end
  
  puts 'Fixation status: X is ' + @f.x.to_s + ' and duration is ' + @f.duration.to_s
end

data = 'id,timestamp,duration\n'
timecodes = ''
results.each do |r|
  timecodes = timecodes + '[' + r[1].to_s + "]\t\n"
  data = data + r[0].to_s + ',' + r[1].to_s + ',' + r[2].to_s + "\n"
  
  puts '#' + r[0].to_s + ',' + r[1].to_s + ',' + r[2].to_s
end

if timecodes.size > 100
  timecodes_file = File.new("newtimecodes.txt",'w+')
  timecodes_file.puts timecodes
end


if data.size > 100
  data_file = File.new("newdata.txt",'w+')
  data_file.puts data
end