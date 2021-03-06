
require_relative 'lense_flares'
#require_relative 'mist'
#
# FIELD GAMESTATE
#
class Field < Chingu::GameState    
  trait :timer
  attr_reader :puck
  
  def initialize
    super
    LenseFlares.load_images $window, './media/lense_flares'
    @lense_flares = LenseFlares.new $window.width/2.0, $window.height/2.0
    @star_flares = {}
    @mist_clear_x = 0.0
    @mist = Ashton::Shader.new fragment: './rb/mist.frag', uniforms: { time: 0.0, alpha: 1.0, mist_color: [230/255.0, 250/255.0, 255/255.0, 1.0], clear_x: @mist_clear_x }
    
    self.input = { :p => Pause,
                   :space => :fire,
                   :j => :toggle_left,
                   :l => :toggle_right,
                   :i => :toggle_up,
                   :k => :toggle_down,
                   :p => Pause,
                   :return => lambda{current_game_state.setup}
                 }

    $window.caption = "Stick Ball! Go team go!"
  end

  def setup
    super
    game_objects.destroy_all
    Referee.destroy_all
    Player1.destroy_all
    Player2.destroy_all

    if @score1_text != nil; @score1_text.destroy; end # if it exists, destroy it
    if @score2_text != nil; @score2_text.destroy; end # if it exists, destroy it

    FireCube.destroy_all
    Star.destroy_all

    Explosion.destroy_all
    Bullet.destroy_all   # destroy lingering GameObjects
#    if @player != nil; @player.destroy; end # if @player exists, destroy it

    @referee = Referee.create(:x => 400, :y => 300, :zorder => Zorder::Main_Character)
#    @referee.input = {:holding_left => :go_left, :holding_right => :go_right, :holding_up => :go_up, :holding_down => :go_down}

    @player1 = Player1.create(:x => 740, :y => 300, :zorder => Zorder::Main_Character)#(:x => $player_x, :y => $player_y, :angle => $player_angle, :zorder => Zorder::Main_Character)
    @player1.input = {:holding_left => :go_left, :holding_right => :go_right, :holding_up => :go_up, :holding_down => :go_down}

    @player2 = Player2.create(:x => 60, :y => 300, :zorder => Zorder::Main_Character)#(:x => $player_x, :y => $player_y, :angle => $player_angle, :zorder => Zorder::Main_Character)
    @player2.input = {:holding_a => :go_left, :holding_d => :go_right, :holding_w => :go_up, :holding_s => :go_down}

#    @player3 = Player2.create(:x => 60, :y => 300, :zorder => Zorder::Main_Character)#(:x => $player_x, :y => $player_y, :angle => $player_angle, :zorder => Zorder::Main_Character)

    @puck = FireCube.create(:x => rand($window.width), :y => rand($window.height), :zorder => Zorder::Projectile)
    @puck_flare = @lense_flares.create @puck.x, @puck.y, Zorder::LenseFlare
    @puck_flare.brightness = 0.25
    @puck_flare.strength = 0.2
    @puck_flare.scale = 1.0

    @ground_y = ($window.height * 0.95).to_i

    $score1 = 0
    $score2 = 0
    @score1_text = Chingu::Text.create(:text=>"", :x=>440, :y=>10, :size=>46)
    @score2_text = Chingu::Text.create(:text=>"", :x=>330, :y=>10, :size=>46)

    @bump = 0
    @bump_delay = 15
    @bounce = 0
    @bounce_delay = 6

    @shake1 = 10
    @shake2 = 5

    @gui = GUI.create      # create GUI
    @gui1 = GUI1.create
  end
  
  def fire;  FireCube.create(:x => rand($window.width), :y => rand($window.height), :zorder => Zorder::Projectile);  end
  def toggle_left;  end
  def toggle_right;  end
  def toggle_up;  end
  def toggle_down;  end

  def blink_flare
    after(30)  { @puck_flare.brightness += 0.6; @puck_flare.strength += 0.3;  }
    after(90)  { @puck_flare.brightness -= 0.3; @puck_flare.strength -= 0.15;  }
    after(100) { @puck_flare.brightness -= 0.3; @puck_flare.strength -= 0.15;  }
  end

  def screen_shake1
    blink_flare
#    if @shaking == false   # if screen shake is cooled down
      game_objects.each do |object|
        object.x += @shake1
        after(30) {object.y += @shake2}
        after(60) {object.x -= @shake1}
        after(90) {object.y -= @shake2}
        after(120) {object.x += @shake1}
        after(150) {object.y += @shake2}
        after(180) {object.x -= @shake1}
        after(210) {object.y -= @shake2}
      end
#      @shaking = true  # screen_shake won't occur again until this becomes false
#      after(1000) {@shaking = false}  # after 1000 ms, screen can shake again
#    end
  end

  def screen_shake2
    blink_flare
#    if @shaking == false   # if screen shake is cooled down
      game_objects.each do |object|  # move each object left first
        object.x -= @shake1
        after(30) {object.y += @shake2}
        after(60) {object.x += @shake1}
        after(90) {object.y -= @shake2}
        after(120) {object.x -= @shake1}
        after(150) {object.y += @shake2}
        after(180) {object.x += @shake1}
        after(210) {object.y -= @shake2}
      end
#      @shaking = true  # screen_shake won't occur again until this becomes false
#      after(1000) {@shaking = false}  # after 1000 ms, screen can shake again
#    end
  end

  def move_referee
    if @referee.y > @puck.y && rand(20) == 1
      @referee.go_up
    end
    if @referee.y < @puck.y && rand(20) == 1
      @referee.go_down
    end
    if @referee.x > @puck.x && rand(20) == 1
      @referee.go_left
    end
    if @referee.x < @puck.x && rand(20) == 1
      @referee.go_right
    end
  end

  def collision_check
    Player1.each_collision(Star) do |player, star|    # PICKUP STARS
      remove_star star
      
      $stars1 += 1             # add star in star meter (gui.rb)
      if $stars1 != 3          # not 3 stars yet?
        $star_grab.play(0.6)   # play normal power-up sound
      else                    # 3 stars?
        $power_up.play(0.6)    # play mighty power-up sound
        $stars1 = 0             # reset star meter
        $weapon += 1           # Upgrade Weapon (see Player.fire in objects.rb)
      end
    end
    Player2.each_collision(Star) do |player, star|    # PICKUP STARS
      remove_star star
      
      $stars2 += 1             # add star in star meter (gui.rb)
      if $stars2 != 3          # not 3 stars yet?
        $star_grab.play(0.6)   # play normal power-up sound
      else                    # 3 stars?
        $power_up.play(0.6)    # play mighty power-up sound
        $stars2 = 0             # reset star meter
        $weapon += 1           # Upgrade Weapon (see Player.fire in objects.rb)
      end
    end
    
    @star_flares.each do |star,flare|
      flare.x = star.x
      flare.y = star.y
    end

    FireCube.each_collision(Player1) do |puck, player|
      if @bump == 0
        player.wobble
        puck.velocity_x = -puck.velocity_x
        puck.die!
        if rand(2) == 1
          puck.velocity_y = -puck.velocity_y
        end
        @bump = @bump_delay
      end
    end
    FireCube.each_collision(Player2) do |puck, player|
      if @bump == 0
        player.wobble
        puck.velocity_x = -puck.velocity_x
        puck.die!
        if rand(2) == 1
          puck.velocity_y = -puck.velocity_y
          @bump = @bump_delay
        end
        @bump = @bump_delay
      end
    end
    FireCube.each_collision(Referee) do |puck, referee|     # ITEM DROPS
      if @bump == 0
        referee.wobble
        add_star :x => referee.x, :y => referee.y, :velocity_x => -puck.velocity_x/3*2, :velocity_y => puck.velocity_y/3*2
        puck.velocity_x = -puck.velocity_x
        puck.die!
        if rand(2) == 1
          puck.velocity_y = -puck.velocity_y
        end
        @bump = @bump_delay
      end
    end

    FireCube.each do |particle|      # SCORING AND WALL-BOUNCING
      if @bounce == 0
        if particle.x < 0 
          particle.velocity_x = -particle.velocity_x
          $score1 += 1
          $bang2.play(0.7)
          if $health2 > 1; $health2 -=1; end
          particle.die!
          screen_shake1
          @bounce = @bounce_delay
        end
        if particle.x > $window.width
          particle.velocity_x = -particle.velocity_x
          $score2 += 1
          $bang1.play(0.8)
          if $health1 > 1; $health1 -=1; end
          particle.die!
          screen_shake2
          @bounce = @bounce_delay
        end
        if particle.y < 0 || particle.y > $window.height
          particle.velocity_y = -particle.velocity_y
          @bounce = @bounce_delay
        end
      end
    end
  end
  
  def add_star options
    star = Star.create options
    flare = @lense_flares.create star.x, star.y, Zorder::LenseFlare
    flare.color = star.color
    flare.strength = 0.25
    flare.brightness = 0.3
    flare.scale = 1.25
    flare.flickering = 0.1
    @star_flares[star] = flare
  end
  
  def remove_star star
    flare = @star_flares.delete star
    @lense_flares.delete flare
    star.destroy
  end

  def draw
    $window.post_process @mist do
      fill_gradient(:from => Color.new(255,0,0,0), :to => Color.new(255,60,60,80), :rect => [0,0,$window.width,@ground_y])
      fill_gradient(:from => Color.new(255,100,100,100), :to => Color.new(255,50,50,50), :rect => [0,@ground_y,$window.width,$window.height-@ground_y])    
      super
      @lense_flares.draw
    end
    $window.caption = "Stick Ball!     Go team go!                                             Objects: #{game_objects.size}, FPS: #{$window.fps}"
    
  end


  def update
    @puck_flare.x = @puck.x
    @puck_flare.y = @puck.y
    @puck_flare.color = @puck.color
    @lense_flares.update
    @mist.time = Gosu.milliseconds/1000.0
    super
    
    #@mist.clear_x = @player2.x
    @mist_clear_x += (@player2.x-@mist_clear_x)*0.1
    @mist.clear_x = @mist_clear_x

    move_referee
    collision_check
    if @bump > 0
      @bump -= 1
    end
    if @bounce > 0
      @bounce -= 1
    end

    @score1_text.text = "#{$score1}"
    @score2_text.text = "#{$score2}"

    #@eyes1.x = @player1.x - 3
    #@eyes1.y = @player1.y - 12
    #@eyes2.x = @player2.x + 3
    #@eyes2.y = @player2.y - 12

    if @player3 != nil
      if @player3.y > @puck.y && rand(5) == 1
        @player3.go_up
      end
      if @player3.y < @puck.y && rand(5) == 1
        @player3.go_down
      end
    end

    self.game_objects.destroy_if { |object| object.color.alpha == 0 }
  end
end



    #
    # GameObject.each_collsion / each_bounding_box_collision wont collide an object with itself
    #
    # FireCube.each_bounding_circle_collision(FireCube) do |cube1, cube2|  # 30 FPS on my computer
    #
    # Let's see if we can optimize each_collision, starts with 19 FPS with radius collision
    # 30 FPS by checking for radius and automatically delegate to each_bounding_circle_collision
    #
    # For bounding_box collision we start out with 7 FPS
    # Got 8 FPS, the bulk CPU consumtion is in the rect vs rect check, not in the loops.
    #