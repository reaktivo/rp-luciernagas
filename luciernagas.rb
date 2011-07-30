# Luciernagas

class Luciernagas < Processing::App

  load_library "control_panel"
  
  PALETTE = { 
    :sand   => 0xF2E8C4, 
    :rain   => 0x98D9B6, 
    :green  => 0x3EC9A7, 
    :water  => 0x2B879E, 
    :black  => 0x616668,
    :light  => 0xc9f202
  }

  def setup
    
    control_panel do |c|
      
      c.slider(:speed, 0..20, 5)
      c.slider(:tail_length, 0..400, 30)
      c.slider(:rotation_max, 0..30, 7)
      c.slider(:target_radius, 5...100, 20)
      c.slider(:spot_distance, 5..200, 80)
      c.button :reset
      
    end
      
    @spotlight = create_spotlight
    @background = load_image('background.png')
    @spot = load_image('spot.png')
    @spots = load_spots(@spot, 4)
    size 1024, 480
    smooth
    reset
    
  end
  
  def reset
    @flyers = []
    100.times do
      @flyers << create_flyer
    end
  end
  
  def draw
    
    image @background, 0, 0
    draw_lights
    draw_flyers
        
  end
  
  def draw_lights
      
      lights = create_graphics width, height, P3D
      lights.begin_draw
      @flyers.each do |flyer|
        lights.push_matrix
        lights.translate flyer[:x], flyer[:y]
        lights.image @spotlight, -@spotlight.width/2, -@spotlight.height/2
        lights.pop_matrix
      end
      
      lights.end_draw
      @spot.mask lights
      image @spot, 0, 0
      

  end
  
  def draw_flyers
    
    rotation_max = @rotation_max/100 * TWO_PI
    
    @flyers.each do |flyer|
      
      # check if point reached
      if dist(flyer[:x], flyer[:y], flyer[:to_x], flyer[:to_y]) < @target_radius
        spot = find_spot_near flyer[:x], flyer[:y], @spot_distance
        flyer[:to_x] = spot[:x]
        flyer[:to_y] = spot[:y]
      end
      
      # set new rotation
      to_rotation = atan2 flyer[:to_y] - flyer[:y], flyer[:to_x] - flyer[:x]
      to_rotation = find_nearest_rotation(flyer[:rotation], to_rotation)
      
      # rotate to new direction
      if flyer[:rotation] < to_rotation
        flyer[:rotation] = flyer[:rotation] + rotation_max
        flyer[:rotation] = to_rotation if flyer[:rotation] > to_rotation
      else
        flyer[:rotation] = flyer[:rotation] - rotation_max
        flyer[:rotation] = to_rotation if flyer[:rotation] < to_rotation
      end
      
      # add tail position
      flyer[:positions].push({ :x => flyer[:x], :y => flyer[:y] })      
      while flyer[:positions].size > @tail_length
        flyer[:positions].shift
      end
      
      # set flyer position
      flyer[:x] = flyer[:x] + @speed * cos(flyer[:rotation])
      flyer[:y] = flyer[:y] + @speed * sin(flyer[:rotation])
      
      # draw flyer tail
      draw_tail flyer[:positions]
      
      # draw flyer
      no_stroke
      fill 201, 242, 2
      push_matrix
      translate flyer[:x], flyer[:y]
      ellipse 0, 0, 5, 5
      pop_matrix
      
    end
  end
  
  def create_flyer
    
    spot = rand_spot
    to_spot = find_spot_near spot[:x], spot[:y], @spot_distance
    rotation = rand * TWO_PI
    
    { 
      :x => spot[:x], :y => spot[:y], 
      :to_x => to_spot[:x], :to_y => to_spot[:y],
      :rotation => rotation, 
      :positions => []
    }
    
  end
  
  def draw_tail(positions)
    
    if positions && positions.size > 0
    
      alpha_add = (255/positions.size).to_i
    
      positions.each_index do |i|
        stroke(255, i * alpha_add)
        if i < positions.size - 2
          line(positions[i][:x], positions[i][:y], positions[i + 1][:x], positions[i + 1][:y])
        end
      end
    
    end
    
  end
  
  def load_spots(spot_image, accuracy=4)
    
    spots = []
    spot_image.load_pixels
    corner_color = spot_image.get 0, 0
    
    y = 0
    while y < spot_image.height
      x = 0
      while x < spot_image.width
        color = spot_image.get(x, y)
        spots << { :x => x, :y => y } if color != corner_color
        x = x + accuracy
      end
      y = y + accuracy
    end
    
    spots
    
  end
  
  def rand_spot
    @spots[rand(@spots.size)]
  end  
  
  def find_spot_near(x, y, distance)
    spot = nil
    until spot && dist(spot[:x], spot[:y], x, y) < distance
      spot = rand_spot
    end
    spot
  end
  
  def find_nearest_rotation(from, to)
    
    dif = (to - from) % TWO_PI;
		if dif != dif % PI
			dif = (dif < 0) ? dif + TWO_PI : dif - TWO_PI;
		end
		
		from + dif
		
  end
  
  def create_spotlight
    size = 60
    
    spotlight = create_graphics size, size, P3D
    spotlight.begin_draw
    spotlight.no_stroke
    spotlight.fill 255, 60
    #spotlight.fill 255, 40
    half_size = size/2
    spotlight.ellipse half_size, half_size, half_size, half_size
    spotlight.filter BLUR, 4
    spotlight.end_draw
    spotlight
    
  end
  
  
end


Luciernagas.new :title => "Luciernagas"