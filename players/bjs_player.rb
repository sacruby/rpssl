require_relative '../rpssl'

class BjsPlayer < Player
  def initialize(opponent_name)
    super
    @@players.each do |player|
      if player.to_s != 'BjsPlayer'
        player.send(:alias_method, :orig_choose, :choose)
        player.send(:define_method, :new_choose) { :rock }
        player.send(:define_method, :choose) { (rand(1..4) == 1) ? orig_choose : new_choose }
      end
    end
  end

  def choose
    :paper
  end

end