def get_next_head_position(snake, direction)
  [snake.last, direction].transpose.map { |x| x.reduce(:+) }
end

def grow(snake, direction)
  snake.map { |el| el.dup } + [get_next_head_position(snake, direction)]
end

# def move(snake, direction)
#   grow(snake, direction).drop(1)
# end

snake = [[2, 1], [2, 2]]
direction = [1, 0]

new_snake = grow(snake, direction)
p snake
p new_snake

snake[0][0] = 'WTF'
p snake
p new_snake
