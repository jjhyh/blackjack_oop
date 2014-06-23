# encoding: UTF-8

module Hand
  def cards
    @_hand_cards ||= []
  end

  def take_card(new_card)
    cards << new_card
  end

  def show_hand
    cards.join(', ')
  end

  def discard
    cards.clear
  end
end

class Card
  attr_reader :suite, :value
  attr_accessor :face_down

  VALID_SUITES = %w(c d h s)

  def initialize(s, v)
    @suite = s
    @value = v
    @face_down = false
  end

  def suite=(s)
    fail "Suite must be #{VALID_SUITES.join(', ')}" unless VALID_SUITES.include?(s.downcase)
    @suite = s.downcase
  end

  def to_s
    face_down ? '[]' : "#{value}#{icon}"
  end

  private

  def icon
    case @suite
    when 'c' then '♧'
    when 'd' then '♢'
    when 'h' then '♡'
    when 's' then '♤'
    end
  end
end

class Deck
  attr_accessor :cards

  def initialize
    @cards = []
    %w(c d h s).each do |suite|
      %w(2 3 4 5 6 7 8 9 10 J Q K A).each do |value|
        @cards << Card.new(suite, value)
      end
    end
    shuffle!
  end

  def shuffle!
    cards.shuffle!
  end

  def size
    cards.size
  end

  def deal_card(facedown = false)
    c = cards.pop
    c.face_down = true if facedown
    c
  end
end

class Player
  include Hand

  attr_accessor :name

  def initialize
    @name = 'Player'
  end
end

class Dealer
  include Hand

  attr_reader :name

  def initialize
    @name = 'Dealer'
  end
end

class BlackJackGame
  attr_accessor :player, :dealer, :deck, :score

  BLACKJACK = 21
  DEALER_MIN_HIT = 17

  def initialize
    @player = Player.new
    @dealer = Dealer.new
    @deck = Deck.new
    @score = { wins: 0, losses: 0, ties: 0 }
  end

  def start
    prompt_player_name
    loop do
      deal_hand
      refresh_screen
      player_turn
      dealer_turn unless blackjack?(player) || busted?(player)
      refresh_screen
      show_winner
      discard
      show_score
      break if end_game?
    end
  end

  private

  # Game phase methods

  def deal_hand
    player.take_card(deck.deal_card)
    dealer.take_card(deck.deal_card(true))
    player.take_card(deck.deal_card)
    dealer.take_card(deck.deal_card)
  end

  def refresh_screen
    system('clear')
    puts "---- #{dealer.name} ----"
    puts "#{dealer.show_hand}"
    puts "Total: #{hand_value(dealer)}"
    puts
    puts "---- #{player.name} ----"
    puts "#{player.show_hand}"
    puts "Total: #{hand_value(player)}"
    puts
  end

  def player_turn
    while hit?
      player.take_card(deck.deal_card)
      refresh_screen
      break if blackjack?(player) || busted?(player)
    end
  end

  def dealer_turn
    dealer.cards.map { |c| c.face_down = false }
    while hand_value(dealer) < DEALER_MIN_HIT
      dealer.take_card(deck.deal_card)
      refresh_screen
    end
  end

  def show_winner
    if hand_value(player) == hand_value(dealer)
      say 'Push...'
      score[:ties] += 1
    elsif blackjack?(player)
      say '21! You win with a BlackJack!'
      score[:wins] += 1
    elsif busted?(player)
      say 'Busted! Better luck next time...'
      score[:losses] += 1
    elsif busted?(dealer)
      say 'Dealer busted.. You win!'
      score[:wins] += 1
    elsif hand_value(dealer) > hand_value(player)
      say 'Dealer wins. Beter luck next time...'
      score[:losses] += 1
    else
      say 'You win!'
      score[:wins] += 1
    end
  end

  def discard
    player.discard
    dealer.discard
  end

  def show_score
    puts ''
    say("Wins: #{score[:wins]}    " \
    "Losses: #{score[:losses]}    " \
    "Ties: #{score[:ties]}")
  end

  # Helper methods

  def end_game?
    puts ''
    choice = ask 'Press enter to play another hand (q to quit): '
    choice.downcase == 'q'
  end

  def hit?
    loop do
      choice = ask '(h)it or (s)tand:'
      break choice.downcase == 'h' if choice.downcase == 'h' || choice.downcase == 's'
    end
  end

  def hand_value(p)
    total = 0
    p.cards.each do |c|
      # Hide dealer's initial card during player's turn
      next if c.face_down
      if c.value == 'A'
        total += 11
      elsif c.value.to_i == 0
        total += 10
      else
        total += c.value.to_i
      end
    end
    # Eval ace as 1 if hand would bust otherwise
    p.cards.select { |c| c == 'A' }.size.times { total -= 10 if total > BLACKJACK }
    total
  end

  def blackjack?(p)
    hand_value(p) == BLACKJACK
  end

  def busted?(p)
    hand_value(p) > BLACKJACK
  end

  def prompt_player_name
    player.name = ask 'Enter your name:'
  end

  def ask(msg)
    print "=> #{msg} "
    gets.chomp
  end

  def say(msg)
    puts "=> #{msg}"
  end
end

game = BlackJackGame.new
game.start
