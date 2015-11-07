class Card
  attr_reader :rank, :suit
	def initialize(rank, suit)
    @rank = rank
    @suit = suit
	end
  def to_s
    "#{rank.to_s.capitalize} of #{suit.to_s.capitalize}"
  end
  def ==(obj)
    (obj.is_a?(Card)) and (rank == obj.rank) and (suit == obj.suit)
  end
end

SUITS = [:clubs, :diamonds, :hearts, :spades].freeze
CARD_SETS = {
  war: [(2..10).to_a, :jack, :queen, :king, :ace].flatten,
  belote: [7, 8, 9, :jack, :queen, :king, 10, :ace],
  sixtysix: [9, :jack, :queen, :king, 10, :ace]
}.freeze

class Deck
  include Enumerable
  def initialize(deck=[])
    @deck = deck
    if deck.empty?
      SUITS.each do |suit|
        get_cards.each do |rank|
          @deck << Card.new(rank, suit)
        end
      end
    end
  end
  def each
    @deck.each { |card| yield card }
  end
  def size
    @deck.size
  end
  def draw_top_card
    @deck.shift
  end
  def draw_bottom_card
    @deck.pop
  end
  def top_card
    @deck.first
  end
  def bottom_card
    @deck.last
  end
  def shuffle
    @deck.shuffle!
    self
  end
  def sort
    suits = [:clubs, :diamonds, :hearts, :spades]
    cards = get_cards
    @deck.sort { |x,y| suits.index(x.suit) <=> suits.index(y.suit) }.sort { |x,y| cards.index(y.rank) <=> cards.index(x.rank) }
  end
  def to_s
    @deck.join("\n")
  end
  def deal
    raise 'deal method not implemented'
    # get_hand.new(@deck.shift(cards_in_hand))
  end
  # def get_hand(which)
  #   WarHand.new(which)
  # end
  private
  def get_cards
    CARD_SETS[get_game_name]
  end
  def get_game_name
    self.class.to_s.match(/([^\/.]*)Deck/)[1].downcase.to_sym
  end
end

class Hand
  def initialize(hand)
    @hand = hand
  end
  def size
    @hand.size
  end
end

class WarHand < Hand
  def play_card
    @hand.shuffle!.shift
  end
  def allow_face_up?
    @hand.size <= 3
  end
end

class WarDeck < Deck
  # def get_cards
  #   game_name = self.class.to_s.match(/([^\/.]*)Deck/)[1].downcase.to_sym
  #   CARD_SETS[game_name]
  # end
  def cards_in_hand
    26
  end
  def deal
    WarHand.new(@deck.shift(cards_in_hand))
  end
end

class BeloteHand < Hand
  def highest_of_suit(suit)
    a = @hand.select { |card| card.suit == suit }
    a.sort { |x,y| get_cards.index(x) <=> get_cards.index(y) }.last
  end
  def get_cards
    [7, 8, 9, :jack, :queen, :king, 10, :ace]
  end
  def belote?
    @hand.group_by { |card| card.suit }.any? { |suit, cards| cards.include?(Card.new(:king, suit)) and cards.include?(Card.new(:queen, suit)) }
  end
  def tierce?
    @hand.group_by { |card| card.suit }.any? { |_, cards| get_cards.each_cons(3).any? { |cons| cards.sort { |x,y| get_cards.index(x.rank) <=> get_cards.index(y.rank) }.map { |card| card.rank }.each_cons(3).any? { |cons2| p cons; p cons2; cons2 == cons } }}
  end
  def quarte?
    @hand.group_by { |card| card.suit }.any? { |_, cards| get_cards.each_cons(4).any? { |cons| cards.sort { |x,y| get_cards.index(x.rank) <=> get_cards.index(y.rank) }.map { |card| card.rank }.each_cons(4).any? { |cons2| p cons; p cons2; cons2 == cons } }}
  end
  def quint?
    @hand.group_by { |card| card.suit }.any? { |_, cards| get_cards.each_cons(5).any? { |cons| cards.sort { |x,y| get_cards.index(x.rank) <=> get_cards.index(y.rank) }.map { |card| card.rank }.each_cons(5).any? { |cons2| p cons; p cons2; cons2 == cons } }}
  end
  def carre_of_jacks?
    @hand.select { |card| card.rank == :jack }.length == 4
  end
  def carre_of_nines?
    @hand.select { |card| card.rank == :nines }.length == 4
  end
  def carre_of_aces?
    @hand.select { |card| card.rank == :ace }.length == 4
  end
end

class BeloteDeck < Deck
  # def get_cards
  #   [7, 8, 9, :jack, :queen, :king, 10, :ace]
  # end
  def cards_in_hand
    8
  end
  def deal
    BeloteHand.new(@deck.shift(cards_in_hand))
  end
end

class SixtySixHand < Hand
  def twenty?(trump_suit)
    @hand.group_by { |card| card.suit }.any? { |suit, cards| suit != trump_suit and cards.include?(Card.new(:king, suit)) and cards.include?(Card.new(:queen, suit))}
  end
  def forty?(trump_suit)
    @hand.group_by { |card| card.suit }.any? { |suit, cards| suit == trump_suit and cards.include?(Card.new(:king, suit)) and cards.include?(Card.new(:queen, suit))}
  end
end

class SixtySixDeck < Deck
  # def get_cards
    
  # end
  def cards_in_hand
    6
  end
  def deal
    SixtySixHand.new(@deck.shift(cards_in_hand))
  end
end

# two_of_clubs  = Card.new(2, :clubs)
# jack_of_clubs = Card.new(:jack, :clubs)

# deck = WarDeck.new([two_of_clubs, jack_of_clubs])

# puts deck.sort.to_a == [jack_of_clubs, two_of_clubs]

# deck  = Deck.new.shuffle
# 47.times { deck.draw_top_card }
# puts deck
# puts "---"
# deck.sort
# puts deck
# deck.each { |card| puts "#{card} !!!" }

# deck = BeloteDeck.new
# hand = BeloteHand.new([Card.new(:king, :spades), Card.new(:queen, :hearts), Card.new(:king, :hearts), Card.new(:ace, :diamonds)]) #deck.deal
# hand = BeloteHand.new([Card.new(:jack, :hearts), Card.new(:jack, :spades), Card.new(:jack, :diamonds), Card.new(:jack, :clubs)])
# puts hand.carre_of_jacks?

# hand = SixtySixHand.new([Card.new(:queen, :diamonds), Card.new(:king, :hearts), Card.new(7, :spades)])
# puts hand.forty?(:hearts)

# puts Card.new(:queen, :spades) == Card.new(:queen, :spades)
# puts Card.new(:queen, :spades) == 3

# deck = Deck.new
# puts deck
# puts deck.draw_top_card
# p deck.size
# puts deck.draw_bottom_card
# p deck.size
# puts deck.top_card
# puts deck.bottom_card
