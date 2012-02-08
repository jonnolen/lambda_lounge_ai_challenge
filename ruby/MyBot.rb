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
  
  directions.each do |direction| 
    if do_move_direction ant, direction
      @food_targets[destination] = ant
      @assigned_ants[ant] = destination
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
  @food_targets = Hash.new
  @assigned_ants = Hash.new
  
  ant_dist = Array.new
  
  ai.food.each do |food|
    ai.my_ants.each do |ant|
      dist = ant.distance_to(food);
      ant_dist.push({ :dist=>dist, :ant => ant, :food_location=>food})
    end
  end
  
  sorted_ants =  ant_dist.sort{ |x,y| x[:dist] <=> y[:dist] }
  
  sorted_ants.each do |ant_distance_tuple|
    food = ant_distance_tuple[:food_location]
    ant = ant_distance_tuple[:ant]
    
    if not @food_targets[food] and not @assigned_ants[ant]
      do_move_location ant, food
    end
  end

#  ai.my_ants.each do |ant|
#		# try to go north, if possible; otherwise try east, south, west.
#		[:N, :E, :S, :W].each do |dir|
#			if do_move_direction ant, dir				
#        break
#			end
#		end
#	end
end
