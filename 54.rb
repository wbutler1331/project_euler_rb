require './lib/string_ext'
require './lib/array_ext'
require './core'

class Card
	include Comparable
	attr_accessor :val, :suit
	def initialize val, suit
		@val = val
		@suit = suit
	end

	def self.parse str
		raise ArgumentError,"String must be two chars" unless str.length == 2 or str.length == 3
		num = str.init
		if num.is_num?
			val = num.to_i
		else
			vals = {
				T: 10,
				J: 11,
				Q: 12,
				K: 13,
				A: 14
			}
			val = vals[num.to_sym]
		end

		Card.new val, str.last
	end

	def <=>(other)
		if self.val > other.val
			1
		elsif self.val < other.val
			-1
		else
			0
		end
	end

	def -(other)
		self.val - other.val
	end
end

class Hand
	include Comparable
	def initialize cards
		raise ArgumentError,"Must  be a 5 card hand..." unless cards.length == 5
		@cards = cards.map do |card|
			if card.class == Card
				card
			elsif card.class == String
				Card.parse card
			else
				raise ArgumentError,"Cards must be either card or string..."
			end
		end
	end

	def groups n=0
		r = @cards.group_by{|c|c.val}.map{|i|i[1]}
		r if n == 0
		r.select{|cs|cs.length==n}
	end

	def cards_by_val
		@cards.sort
	end

	def high_card
		[cards_by_val.last]
	end

	def one_pair
		pairs = groups 2
		return nil unless pairs.length == 1
		pairs.first
	end

	def two_pairs
		pairs = groups 2
		return nil unless pairs.length == 2
		pairs.inject(:+)
	end

	def three_of_a_kind
		threes = groups 3
		return nil unless threes.length == 1
		threes.first
	end

	def straight
		return nil unless cards_by_val.consecutive_ascending?
		cards_by_val
	end

	def flush
		return nil unless @cards.all? { |c| c.suit == @cards.first.suit }
		@cards
	end

	def full_house
		three = three_of_a_kind
		pair  = one_pair
		return nil if three.nil? or pair.nil?
		three.concat pair
	end

	def four_of_a_kind
		fours = groups 4
		return nil unless fours.length == 1
		fours.first
	end

	def straight_flush
		return nil if straight.nil? or flush.nil?
		straight
	end

	def royal_flush
		return nil if straight.nil? or flush.nil? or cards_by_val.last.val != 14
		@cards
	end

	def analyze
		rules = {
			10 => :royal_flush,
			9  => :straight_flush,
			8  => :four_of_a_kind,
			7  => :full_house,
			6  => :flush,
			5  => :straight,
			4  => :three_of_a_kind,
			3  => :two_pairs,
			2  => :one_pair,
			1  => :high_card
		}
		rules.map     { |score, rule| [score,self.send(rule)] } \
		     .select  { |result|      !result[1].nil? } \
				 .sort_by { |result|      result[0] } \
				 .last
	end

	def <=>(hand2)
		score1,cards1 = self.analyze
		score2,cards2 = hand2.analyze
		if score1 > score2
			return 1
		elsif score2 > score1
			return -1
		else
      deltas = cards1.group_by do |c| 
				c.val
			end.sort_by do |c,g| 
				-g.length
			end.map(&:first).deltas(
				cards2.group_by do |c|
					c.val
				end.sort_by do |c,g| 
					-g.length
				end.map(&:first)
			).select do |d|
				d!=0
			end.reverse

			if deltas.length > 0
				(deltas.first.sign+"1").to_i
			else
				deltas = self.cards_by_val.deltas(hand2.cards_by_val).select{|d|d!=0}
				if deltas.length > 0
					(deltas.last.sign+"1").to_i
				else
					0
				end
			end
		end
	end
end

# test data
# puts (Hand.new(["5H", "5C", "6S", "7S", "KD"]) > Hand.new(["2C", "3S", "8S", "8D", "TD"])) # => false
# puts (Hand.new(["5D", "8C", "9S", "JS", "AC"]) > Hand.new(["2C", "5C", "7D", "8S", "QH"])) # => true
# puts (Hand.new(["2D", "9C", "AS", "AH", "AC"]) > Hand.new(["3D", "6D", "7D", "TD", "QD"])) # => false
# puts (Hand.new(["4D", "6S", "9H", "QH", "QC"]) > Hand.new(["3D", "6D", "7H", "QD", "QS"])) # => true
# puts (Hand.new(["2H", "2D", "4C", "4D", "4S"]) > Hand.new(["3C", "3D", "3S", "9S", "9D"])) # => true

hands = IO.read("files/p054_poker.txt").each_line.map do |line|
	cards = line.split " "
	[Hand.new(cards[0..4]), Hand.new(cards[5..9])]
end

results = hands.select do |hand1,hand2|
	hand1 > hand2
end

puts results.length
