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

CARDS_IN_HAND = {
  war: 26,
  belote: 8,
  sixtysix: 6
}.freeze

class Deck
  include Enumerable

  def initialize(deck = [])
    @deck = deck.empty? ? generate_deck : deck
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
    sort_by_rank(sort_by_suit(@deck))
    self
  end

  def to_s
    @deck.join("\n")
  end

  def deal
    eval "#{get_game_name}Hand.new(@deck.shift(cards_in_hand))"
  end

  private

  def get_cards
    CARD_SETS[get_game_name.downcase.to_sym]
  end

  def get_game_name
    self.class.to_s.match(/([^\/.]*)Deck/)[1]
  end

  def generate_deck
    SUITS.each_with_object([]) do |suit, deck|
      get_cards.each do |rank|
        deck << Card.new(rank, suit)
      end
    end
  end

  def sort_by_suit(deck)
    deck.sort! { |x,y| SUITS.index(x.suit) <=> SUITS.index(y.suit) }
  end

  def sort_by_rank(deck)
    deck.sort! { |x,y| get_cards.index(y.rank) <=> get_cards.index(x.rank) }
  end

  def cards_in_hand
    CARDS_IN_HAND[get_game_name.downcase.to_sym]
  end
end

class Hand
  def initialize(hand)
    @hand = hand
  end

  def size
    @hand.size
  end

  private
  def of_same_suit
    @hand.group_by { |card| card.suit }.any? do |suit, cards|
      yield suit, cards.map { |c| c.rank }
    end
  end
end

class WarHand < Hand
  def play_card
    @hand.delete_at(rand(@hand.length))
  end
  def allow_face_up?
    @hand.size <= 3
  end
end

class WarDeck < Deck
end

class BeloteHand < Hand
  def highest_of_suit(suit)
    sort(@hand.select { |card| card.suit == suit }).last
  end
  def get_cards
    [7, 8, 9, :jack, :queen, :king, 10, :ace]
  end
  def belote?
    of_same_suit do |suit, cards|
      cards.include?(:queen) and cards.include?(:king)
    end
  end
  def tierce?
    of_same_suit { |_, cards| has_n_consecutive_cards(3, cards) }
  end
  def quarte?
    of_same_suit { |_, cards| has_n_consecutive_cards(4, cards) }
  end
  def quint?
    of_same_suit { |_, cards| has_n_consecutive_cards(5, cards) }
  end
  def carre_of_jacks?
    has_four(:jack)
  end
  def carre_of_nines?
    has_four(9)
  end
  def carre_of_aces?
    has_four(:ace)
  end

  private
  def sort(cards)
    cards.sort { |x,y| get_cards.index(x) <=> get_cards.index(y) }
  end
  def has_n_consecutive_cards(n, cards)
    get_cards.each_cons(n).any? do |consequence|
      consequence.all? { |card| cards.include?(card) }
    end
  end
  def has_four(rank)
    @hand.select { |card| card.rank == rank }.length == 4
  end
end

class BeloteDeck < Deck
end

class SixtySixHand < Hand
  def twenty?(trump_suit)
    of_same_suit do |suit, cards|
      suit != trump_suit and cards.include?(:king) and cards.include?(:queen)
    end
  end
  def forty?(trump_suit)
    of_same_suit do |suit, cards|
      suit == trump_suit and cards.include?(:king) and cards.include?(:queen)
    end
  end
end

class SixtySixDeck < Deck
end
