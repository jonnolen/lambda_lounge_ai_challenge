# Ants AI Challenge framework
# by Matma Rex (matma.rex@gmail.com)
# Released under CC-BY 3.0 license

# Represents a single ant.
class Ant
	# Owner of this ant. If it's 0, it's your ant.
	attr_accessor :owner
	# Square this ant sits on.
	attr_accessor :square
	
	attr_accessor :alive, :ai
	
	def initialize alive, owner, square, ai
		@alive, @owner, @square, @ai = alive, owner, square, ai
	end
	
	# True if ant is alive.
	def alive?; @alive; end
	# True if ant is not alive.
	def dead?; !@alive; end
	
	# Equivalent to ant.owner==0.
	def mine?; owner==0; end
	# Equivalent to ant.owner!=0.
	def enemy?; owner!=0; end
	
	# Returns the row of square this ant is standing at.
	def row; @square.row; end
	# Returns the column of square this ant is standing at.
	def col; @square.col; end
	
	# Order this ant to go in given direction. Equivalent to ai.order ant, direction.
	def order direction
		@ai.order self, direction
	end
  
  def directions_to(destination)
    half_height = @ai.rows / 2
    half_width = @ai.cols / 2
    
    d = Array.new
    
    if (self.row < destination.row)
      if destination.row - self.row >= half_height then d.push(:N) end
      if destination.row - self.row < half_height then d.push(:S) end
    end
    if (destination.row < self.row)
      if self.row - destination.row >= half_height then d.push(:S) end
      if self.row - destination.row < half_height then d.push(:N) end
    end
    if (self.col < destination.col)
      if destination.col - self.col >= half_width then d.push(:W) end
      if destination.col - self.col < half_width then d.push(:E) end
    end
    if (destination.col < self.col)
      if self.col - destination.col >= half_width then d.push(:E) end
      if self.col - destination.col < half_width then d.push(:W) end
    end
    d
  end
  
  def distance_to(destination)
    vertical_dif = (self.col - destination.col).abs
    horizontal_dif = (self.row - destination.row).abs
    
    vertical_distance = vertical_dif < @ai.cols - vertical_dif ? vertical_dif : @ai.cols-vertical_dif
    horizontal_distance = horizontal_dif < @ai.rows - horizontal_dif ? horizontal_dif : @ai.rows - horizontal_dif
    
    return vertical_distance + horizontal_distance
  end
end

# Represent a single field of the map.
class Square
	# Ant which sits on this square, or nil. The ant may be dead.
	attr_accessor :ant
	# Which row this square belongs to.
	attr_accessor :row
	# Which column this square belongs to.
	attr_accessor :col
	
	attr_accessor :water, :food, :hill, :ai
	
	def initialize water, food, hill, ant, row, col, ai
		@water, @food, @hill, @ant, @row, @col, @ai = water, food, hill, ant, row, col, ai
	end
	
	# Returns true if this square is not water. Square is passable if it's not water, it doesn't contain alive ants and it doesn't contain food.
	def land?; !@water; end
	# Returns true if this square is water.
	def water?; @water; end
	# Returns true if this square contains food.
	def food?; @food; end
	# Returns owner number if this square is a hill, false if not
	def hill?; @hill; end
	# Returns true if this square has an alive ant.
	def ant?; @ant and @ant.alive?; end;
	
	# Returns a square neighboring this one in given direction.
	def neighbor direction
		direction=direction.to_s.upcase.to_sym # canonical: :N, :E, :S, :W
	
		case direction
		when :N
			row, col = @ai.normalize @row-1, @col
		when :E
			row, col = @ai.normalize @row, @col+1
		when :S
			row, col = @ai.normalize @row+1, @col
		when :W
			row, col = @ai.normalize @row, @col-1
		else
			raise 'incorrect direction'
		end
		
		return @ai.map[row][col]
	end
end

class AI
	# Map, as an array of arrays.
	attr_accessor :map
  
  attr_reader :rows
  attr_reader :cols
	# Number of current turn. If it's 0, we're in setup turn. If it's :game_over, you don't need to give any orders; instead, you can find out the number of players and their scores in this game.
	attr_accessor	:turn_number
	
	# Game settings. Integers.
	attr_accessor :loadtime, :turntime, :rows, :cols, :turns, :viewradius2, :attackradius2, :spawnradius2, :seed
	# Radii, unsquared. Floats.
	attr_accessor :viewradius, :attackradius, :spawnradius
	
	# Number of players. Available only after game's over.
	attr_accessor :players
	# Array of scores of players (you are player 0). Available only after game's over.
	attr_accessor :score

	# Initialize a new AI object. Arguments are streams this AI will read from and write to.
	def initialize stdin=$stdin, stdout=$stdout
		@stdin, @stdout = stdin, stdout

		@map=nil
		@turn_number=0
		
		@my_ants=[]
		@enemy_ants=[]
		@food=[]
		@did_setup=false
    @vision = nil
    @vision_offsets_2 = nil
	end
	
	# Returns a read-only hash of all settings.
	def settings
		{
			:loadtime => @loadtime,
			:turntime => @turntime,
			:rows => @rows,
			:cols => @cols,
			:turns => @turns,
			:viewradius2 => @viewradius2,
			:attackradius2 => @attackradius2,
			:spawnradius2 => @spawnradius2,
			:viewradius => @viewradius,
			:attackradius => @attackradius,
			:spawnradius => @spawnradius,
			:seed => @seed
		}.freeze
	end
	
	# Zero-turn logic. 
	def setup # :yields: self
		read_intro
		yield self
		
		@stdout.puts 'go'
		@stdout.flush
		
		@map=Array.new(@rows){|row| Array.new(@cols){|col| Square.new false, false, false, nil, row, col, self } }
		@did_setup=true
	end
	
	# Turn logic. If setup wasn't yet called, it will call it (and yield the block in it once).
	def run &b # :yields: self
		setup &b if !@did_setup
		
		over=false
		until over
			over = read_turn
			yield self
			
			@stdout.puts 'go'
			@stdout.flush
		end
	end

	# Internal; reads zero-turn input (game settings).
	def read_intro
		rd=@stdin.gets.strip
		warn "unexpected: #{rd}" unless rd=='turn 0'

		until((rd=@stdin.gets.strip)=='ready')
			_, name, value = *rd.match(/\A([a-z0-9]+) (\d+)\Z/)
			
			case name
			when 'loadtime'; @loadtime=value.to_i
			when 'turntime'; @turntime=value.to_i
			when 'rows'; @rows=value.to_i
			when 'cols'; @cols=value.to_i
			when 'turns'; @turns=value.to_i
			when 'viewradius2'; @viewradius2=value.to_i
			when 'attackradius2'; @attackradius2=value.to_i
			when 'spawnradius2'; @spawnradius2=value.to_i
			when 'seed'; @seed=value.to_i
			else
				warn "unexpected: #{rd}"
			end
		end
		
		@viewradius=Math.sqrt @viewradius2
		@attackradius=Math.sqrt @attackradius2
		@spawnradius=Math.sqrt @spawnradius2
	end
	
	# Internal; reads turn input (map state).
	def read_turn
		ret=false
		rd=@stdin.gets.strip
		
		if rd=='end'
			@turn_number=:game_over
			
			rd=@stdin.gets.strip
			_, players = *rd.match(/\Aplayers (\d+)\Z/)
			@players = players.to_i
			
			rd=@stdin.gets.strip
			_, score = *rd.match(/\Ascore (\d+(?: \d+)+)\Z/)
			@score = score.split(' ').map{|s| s.to_i}
			
			ret=true
		else
			_, num = *rd.match(/\Aturn (\d+)\Z/)
			@turn_number=num.to_i
		end
	
		# reset the map data
		@map.each do |row|
			row.each do |square|
				square.food=false
				square.ant=nil
				square.hill=false
			end
		end
		
		@my_ants = []
		@enemy_ants = []
		@food = []
    @my_hills = []
    @enemy_hills = []
    @vision = nil
    @vision_offsets_2 = nil
    
		until((rd=@stdin.gets.strip)=='go')
			_, type, row, col, owner = *rd.match(/(w|f|h|a|d) (\d+) (\d+)(?: (\d+)|)/)
			row, col = row.to_i, col.to_i
			owner = owner.to_i if owner
			
			case type
			when 'w'
				@map[row][col].water=true
			when 'f'
				@map[row][col].food=true
        food.push @map[row][col]
			when 'h'
				@map[row][col].hill=owner
        if (owner == 0)
          my_hills.push @map[row][col]
        else
          enemy_hills.push @map[row][col]
        end
			when 'a'
				a=Ant.new true, owner, @map[row][col], self
				@map[row][col].ant = a
				
				if owner==0
					my_ants.push a
				else
					enemy_ants.push a
				end
			when 'd'
				d=Ant.new false, owner, @map[row][col], self
				@map[row][col].ant = d
			when 'r'
				# pass
			else
				warn "unexpected: #{rd}"
			end
		end

		return ret
	end
	
	
	
	# call-seq:
	#   order(ant, direction)
	#   order(row, col, direction)
	#
	# Give orders to an ant, or to whatever happens to be in the given square (and it better be an ant).
	def order a, b, c=nil
		if !c # assume two-argument form: ant, direction
			ant, direction = a, b
			@stdout.puts "o #{ant.row} #{ant.col} #{direction.to_s.upcase}"
		else # assume three-argument form: row, col, direction
			row, col, direction = a, b, c
			@stdout.puts "o #{row} #{col} #{direction.to_s.upcase}"
		end
	end
	
	
	
	
	# Returns an array of your alive ants on the gamefield.
	def my_ants; @my_ants; end
	# Returns an array of alive enemy ants on the gamefield.
	def enemy_ants; @enemy_ants; end
	# Returns an array of known food sources on the gamefield.
  def food; @food; end
  def my_hills; @my_hills end
  def enemy_hills; @enemy_hills end

  
	# If row or col are greater than or equal map width/height, makes them fit the map.
	#
	# Handles negative values correctly (it may return a negative value, but always one that is a correct index).
	#
	# Returns [row, col].
	def normalize row, col
		[row % @rows, col % @cols]
	end
  
  def visible? location
    unless @vision
      unless @vision_offsets_2
        @vision_offsets_2 = []
        mx = Integer(viewradius)
        (-mx..mx+1).each do |deltaRow|
          (-mx..mx+1).each do |deltaCol|
            distance = deltaRow**2 + deltaCol**2
            if (distance <= viewradius2)
              @vision_offsets_2.push({:row=> (deltaRow % rows) - rows,
                                     :col=> (deltaCol % cols) - cols})
            end
          end
        end
      end
      
      @vision = (0..rows-1).collect{Array.new(cols, false)}
      
      my_ants.each do |ant|
        row,col = ant.square.row, ant.square.col
        @vision_offsets_2.each do |loc|
          dRow,dCol = loc[:row],loc[:col]
          @vision[row + dRow][col +dCol] = true
        end
      end
    end
       
    return @vision[location[:row]][location[:col]]
  end
end

