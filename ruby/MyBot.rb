$:.unshift File.dirname($0)
require 'ants.rb'

ai=AI.new

def do_move_direction ant, direction
    new_loc =  ant.square.neighbor(direction);
    if new_loc.land? and not  new_loc.ant? and not @orders.has_key? new_loc
      ant.order direction
      @orders[new_loc] = ant
      @ordered_ants[ant] = new_loc
      return true
    else
      return false
    end
end

def do_move_location ant, destination
  directions = ant.directions_to(destination);
  
  directions.each do |direction| 
    if do_move_direction ant, direction
      @targets[destination] = ant
      @assigned_ants[ant] = destination
      return true
    end  
  end
  
  return false
  
end

ai.setup do |ai|
	# your setup code here, if any
  @unseen = Array.new
  ai.rows.times do |row|
    ai.cols.times do |col|
      @unseen.push({ :row=>row, :col=>col })
    end
  end
end


ai.run do |ai|
  @orders = Hash.new
  @ordered_ants = Hash.new
  
  @targets = Hash.new
  @assigned_ants = Hash.new
  
  ant_dist = Array.new
  ai.my_hills do |hill|
    orders[hill] = nil    
  end
  
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
    
    if not @targets[food] and not @assigned_ants[ant]
      do_move_location ant, food
    end
  end
  
  @unseen.each do |loc|
    if ai.visible? loc
      @unseen.delete loc
    end
  end
  
  ai.my_ants.each do |ant|
    unless @ordered_ants.has_key? ant
      unseen_distances = @unseen.collect do |loc|
        square = ai.map[loc[:row]][loc[:col]]
        { :dist=>ant.distance_to(square), :loc=>square}
      end
      unseen_distances.sort{ |x,y| x[:dist] <=> y[:dist]}
      unseen_distances.each do |item|
        if do_move_location ant, item[:loc]
          break
        end
      end
    end
  end
  
  ai.my_hills.select{ |hill| hill.ant? and  hill.ant.owner == 0 }.each do |hill|
    if not @orders.values.include? hill
      [:N,:E,:S,:W].each do |dir|
        if do_move_direction hill.ant, dir
          break
        end
      end
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
