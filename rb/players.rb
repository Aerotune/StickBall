DEBUG = false  # Set to true to see bounding circles used for collision detection


class CharWheel < Chingu::GameObject
  def setup
    @speed = 3
    @picture = ["boy", "monk", "tanooki",
                "cult_leader", "villager", "knight",
                "sorceror" ]
#    @picture = ["players/boy.png", "players/monk.png", "players/tanooki.png",
#                "players/cult_leader.png", "players/villager.png", "players/knight.png",
#                "players/sorceror.png" ]
    @p = 0
    @image = Gosu::Image["players/#{@picture[@p]}.png"]
#    @image = Gosu::Image[@picture[@p]]
    @click = Sound["media/audio/keypress.ogg"]
    @ready = false
  end

  def p
    @picture[@p]
  end

  def ready
    @ready = true
  end

=begin
  def go_left
    if @ready == false
      @click.play
      if @p > 0
        @p -= 1
      else
        @p = 6
      end
      @image = Gosu::Image["players/#{@picture[@p]}.png"]
      @text.text = "#{@picture[@p]}"
      $image1 = "#{@picture[@p]}"
#      @image = Gosu::Image[@picture[@p]]
    end
  end

  def go_right
    if @ready == false
      @click.play
      if @p < 6
        @p += 1
      else
        @p = 0
      end
      @image = Gosu::Image["players/#{@picture[@p]}.png"]
      $image1 = "#{@picture[@p]}"
#      @image = Gosu::Image[@picture[@p]]
    end
  end
=end
  def go_up
    @y -= @speed
  end

  def go_down
    @y += @speed
  end

  def enlargen
    if self.factor < 3.0
      self.factor *= 1.02
    end
  end

  def update
    if @ready == true
      enlargen
    end
  end

end


class CharWheel1 < CharWheel
  def setup
    self.factor_x = -1
    @speed = 3
    @picture = ["boy", "monk", "tanooki",
                "cult_leader", "villager", "knight",
                "sorceror" ]
#    @picture = ["players/boy.png", "players/monk.png", "players/tanooki.png",
#                "players/cult_leader.png", "players/villager.png", "players/knight.png",
#                "players/sorceror.png" ]
    @p = @picture.index($image1)
    @image = Gosu::Image["players/#{@picture[@p]}.png"]
#    @image = Gosu::Image[@picture[@p]]
    @click = Sound["media/audio/keypress.ogg"]
    @ready = false

#    @caption = Chingu::Text.create("ttt#{$image1}", :y => self.y - 150, :size => 45, :color => Colors::Dark_Orange, :zorder => Zorder::GUI)
#    @caption.x = self.x - @caption.width/2 # center text
  end


  def go_left
    if @ready == false
      @click.play
      if @p > 0
        @p -= 1
      else
        @p = 6
      end
      @image = Gosu::Image["players/#{@picture[@p]}.png"]
#      @caption.text = "#{@picture[@p]}"
#      @caption.x = @x - @caption.width/2 # center text
      $image1 = "#{@picture[@p]}"
#      @image = Gosu::Image[@picture[@p]]
    end
  end
  def go_right
    if @ready == false
      @click.play
      if @p < 6
        @p += 1
      else
        @p = 0
      end
      @image = Gosu::Image["players/#{@picture[@p]}.png"]
      $image1 = "#{@picture[@p]}"
#      @image = Gosu::Image[@picture[@p]]
    end
  end
end


class CharWheel2 < CharWheel
  def setup
    super
    @p = @picture.index($image2)
    @image = Gosu::Image["players/#{@picture[@p]}.png"]
  end
  def go_left
    if @ready == false
      @click.play
      if @p > 0
        @p -= 1
      else
        @p = 6
      end
      @image = Gosu::Image["players/#{@picture[@p]}.png"]
      $image2 = "#{@picture[@p]}"
#      @image = Gosu::Image[@picture[@p]]
    end
  end
  def go_right
    if @ready == false
      @click.play
      if @p < 6
        @p += 1
      else
        @p = 0
      end
      @image = Gosu::Image["players/#{@picture[@p]}.png"]
      $image2 = "#{@picture[@p]}"
#      @image = Gosu::Image[@picture[@p]]
    end
  end
end

class Player < Chingu::GameObject
  require_relative 'player/eyes'
  require_relative 'player/mouth'
  trait :bounding_box, :debug => DEBUG
  traits :velocity, :collision_detection
  attr_reader :direction
  
  def setup
    @speed = 12
    @squeeze_y = 1.0
    @direction = 1
    @hit_time = Gosu.milliseconds - 3000
    @wobble_resistance = 0.005
    @eyes = Eyes.new self
    @mouth = Mouth.new self
  end
  def go_left
    @x -= @speed
  end
  def go_right
    @x += @speed
  end
  def go_up
    @y -= @speed
    @squeeze_y = walk_wobble_factor
  end
  def go_down
    @y += @speed
    @squeeze_y = walk_wobble_factor
  end
  
  def walk_wobble_factor
    #sin curve between 1..0.8 at 5hz
    1 - (Math.sin(Gosu.milliseconds/(Math::PI*10))+1)/10.0
  end
  
  def hit_wobble_factor
    time = Gosu.milliseconds - @hit_time
    
    1 - (Math.sin(time/25.0)/(time**1.7*@wobble_resistance))
  end
  
  def wobble
    @hit_time = Gosu.milliseconds - 30
  end
  
  def update
    self.factor_y = @squeeze_y
    self.factor_x = hit_wobble_factor * @direction
    @squeeze_y = 1.0
    @eyes.update
    @mouth.update
  end
  
  def draw
    super
    @eyes.draw
    @mouth.draw
  end
end


class Referee < Player
    trait :bounding_circle, :debug => DEBUG
  def setup
    super
    @image = Gosu::Image["players/referee.png"]
#    @picture2 = Gosu::Image["players/player_blink.png"]
    @rand = 30
    @speed = 5
    @wobble_resistance = 0.001
    cache_bounding_circle
  end

  def update
    super
    @mouth.scale_y = -0.15
    go_right if rand(@rand) == 5
    go_down  if rand(@rand) == 5
    go_left  if rand(@rand) == 5
    go_up    if rand(@rand) == 5
  end
end


#
#  PLAYER 1 CLASS
#
class Player1 < Player
  attr_reader :health, :score
  def initialize(health)
    super
    @image = Gosu::Image["players/#{$image1}.png"]
    self.factor_x = -1
    @direction = -1 
    cache_bounding_box
  end

end


#
#  PLAYER 2 CLASS
#
class Player2 < Player
  attr_reader :health, :score
  def initialize(health)
    super
    @image = Gosu::Image["players/#{$image2}.png"]
    cache_bounding_box
  end
end


#
#  KNIGHT
#    called in beginning.rb, in Introduction gamestate
class Knight < Chingu::GameObject
  def initialize(options)
    super
    @image = Image["players/knight.png"]
    @voice = Sound["audio/mumble.ogg"]
    @velox = 0     # x velocity starts as 0
    @veloy = 0     # y velocity starts as 0
    @factoring = 1 # used for shrinking Knight when he enters the ship
  end
  def movement   # called in Introduction gamestate
    @velox = -7  # move left
  end
  def enter_ship # called in Introduction gamestate
    @veloy = 2
    @factoring = 0.98
  end
  def speak      # called in Introduction gamestate
    @voice.play
  end
  def update
    self.factor *= @factoring
    @x += @velox
    @y += @veloy
    if @x <= 400; @velox = 0; end
    if @y >= 450; @veloy = 0; end
  end
end


