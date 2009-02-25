require 'rubygems'
require 'ftools'
#require 'rvideo'
require 'csv'

if ARGV.size == 1
  puts 'Data: ' + ARGV[0].to_s
  data_file = ARGV[0].to_s
  offset = nil
elsif ARGV.size == 2
  puts 'Data: ' + ARGV[0].to_s
  puts 'Offset (in): ' + ARGV[1].to_s
    data_file = ARGV[0].to_s
  offset = ARGV[1].to_s
else
  raise "Expected: extract.rb <datafile> <optional offset>" if ARGV.size < 1  
end

file_break = (data_file =~ /\./)
if data_file =~ /\./
  puts "location: " + file_break.to_s
  file_root = data_file[0,file_break]
else
  file_root = "_"
end


class Float
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end

  def ceil_to(x)
    (self * 10**x).ceil.to_f / 10**x
  end

  def floor_to(x)
    (self * 10**x).floor.to_f / 10**x
  end
end

class Fixation
  attr_accessor :x, :y, :start, :centertime, :duration, :id, :offset
  
  #a new fixation requires x,y coordinates and a start time
  def initialize(x,y,start)  
       @x = x  
       @y = y
       @start = start
       @duration = 1  
       @offset = 0
  end
  
  def formatted_old_timestamp
    @fields = @start.split(/\./) 
    return @fields[0] + '.' + (@fields[1].to_i * 10).to_s
  end
  
  
  def formatted_timestamp
    @fields = @centertime.split(/\./) 
    #return @fields[0] + '.' + (@fields[1].to_i * 10).to_s
    
    #try returning 30 fps
    @frame_adjusted = @fields[0] + '.' + (@fields[1].to_f.round_to(0) * 0.33).to_i.to_s
    @fa = @frame_adjusted.split(/:/)
    
    return @fa[0].to_s + ':' + (@fa[1].to_i-(@offset.to_i)).to_s + ':' + @fa[2].to_s
  end
  
end

#SET GLOBAL PREF (these should be customizable eventually)
  #max allowable square of x coordinate difference between two frames of a single fixation
  x_squared = 14
  #max allowable square of y coordinate difference between two frames of a single fixation
  y_squared = 14
  #min consecutive frames to be saved as a valid fixation
  required_frames = 3
  #transform fraction of a second
  #sec_transform = 10
  
puts 'Mobile Eye Data Extraction'
puts 'By Christopher Correa'
puts 'Version 0.2 (January 2009)'
puts '-------'
puts 'Analyzing ' + file_root + '...'

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
      @f.x = d[2].to_f 
      @f.y = d[3].to_f 
      if(@f.duration == 2)
        @f.offset = offset
        @f.centertime =  d[0].to_s
      end
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

puts 'Writing output files for ' + file_root + '...'

# WRITE Timestamps
  if offset.to_i>0
    timecodes_file = File.new(file_root + "_timecodes_" + offset.to_s + ".txt",'w+')
  else
    timecodes_file = File.new(file_root + "_timecodes.txt",'w+')
  end
  
timecodes_file.puts timecodes
puts "- Created " + timecodes_file.inspect.to_s

# WRITE data
if offset.to_i>0
  data_file = File.new(file_root + "_data_" + offset.to_s + ".txt",'w+')
else
  data_file = File.new(file_root + "_data.txt",'w+')
end

data_file.puts data
puts "- Created " + data_file.inspect.to_s

puts "Complete!"
