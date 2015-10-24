def multiples_of(number)
  (2..number).select { |n| number % n == 0 }
end

class RationalSequence
  include Enumerable

  def initialize(limit)
    @limit = limit
  end

  def each
    (1..Float::INFINITY).lazy.flat_map do |n|
      enum_for(:generate_nth_diagonal, n).to_a
    end.take(@limit).each { |rational| yield rational }
  end

  private
  def generate_nth_diagonal(n)
    range = n.odd? ? 1.upto(n) : n.downto(1)

    range.each do |numerator|
      denominator = n - numerator + 1
      if not_encountered_before?(numerator, denominator)
        yield Rational(numerator, denominator)
      end
    end
  end

  def not_encountered_before?(numerator, denominator)
    ((multiples_of numerator) & (multiples_of denominator)).empty?
  end
end

class Integer
  def prime?
    return false if self == 1
    (2..self / 2).none? { |n| self % n == 0 }
  end
end

class PrimeSequence
  include Enumerable

  def initialize(limit)
    @limit = limit
  end

  def each
    primes = (2..Float::INFINITY).lazy.select { |n| n.prime? }
    primes.take(@limit).each { |prime| yield prime }
  end
end

class FibonacciSequence
  include Enumerable

  def initialize(limit, first: 1, second: 1)
    @limit = limit
    @first = first
    @second = second
  end

  def each
    count = 0
    previous, current = @first, @second
    while count < @limit
      yield previous
      count += 1
      current, previous = current + previous, current
    end
  end
end

module DrunkenMathematician
  module_function

  def meaningless(n)
    group1, group2 = RationalSequence.new(n).partition do |rational|
      rational.numerator.prime? or rational.denominator.prime?
    end

    (group1.reduce(:*) or 1) / (group2.reduce(:*) or 1)
  end

  def aimless(n)
    PrimeSequence.new(n).each_slice(2).map do |pair|
      Rational(pair.first, pair.last)
    end.reduce(:+)
  end

  def worthless(n)
    (1..Float::INFINITY).lazy.map do |i|
      RationalSequence.new(i).to_a
    end.take_while do |seq|
      seq.reduce(:+) <= FibonacciSequence.new(n).to_a.last
    end.to_a.last
  end
end