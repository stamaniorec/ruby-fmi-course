def complement(f)
  lambda { |*args| not f.call(*args) }
end

def compose(f, g)
  lambda { |*args| f.call(g.call(*args)) }
end