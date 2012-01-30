$:.unshift File.dirname($0)
require 'ants.rb'

ai=AI.new

def do_move_direction ant, direction
    new_loc =  ant.square.neighbor(direction);
    if new_loc.land? and not  new_loc.ant? and not @orders[new_loc]
      ant.order direction
      @orders[new_loc] = ant.square
      return true
    else
      return false
    end
end

def do_move_location ant, destination
  directions = ant.directions_to(destination);
  
  direction.each do |direction| 
    if do_move_direction ant, direction
      targets[destination] = ant
      return true
    end  
  end
  
  return false
  
end

ai.setup do |ai|
	# your setup code here, if any

end


ai.run do |ai|
  @orders = Hash.new
	@targets = Hash.new
  
  ai.my_ants.each do |ant|
		# try to go north, if possible; otherwise try east, south, west.
		[:N, :E, :S, :W].each do |dir|
			if do_move_direction ant, dir				
        break
			end
		end
	end
end
