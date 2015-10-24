def get_next_head_position(snake, direction)
  [snake.last, direction].transpose.map { |x| x.reduce(:+) }
end

def grow(snake, direction)
  snake.map { |item| item.dup } + [get_next_head_position(snake, direction)]
end

def move(snake, direction)
  grow(snake, direction).drop(1)
end

def out_of_bounds?(x, y, dimensions)
  x < 0 or x >= dimensions[:width] or y < 0 or y >= dimensions[:height]
end

def generate_fruit(dimensions)
  [rand(dimensions[:width]), rand(dimensions[:height])]
end

def fruit_position_valid?(fruit, food, snake, dimensions)
  on_snake = snake.include?(fruit)
  on_food = food.include?(fruit)
  out_of_bounds = out_of_bounds?(*fruit, dimensions)

  not (on_snake or on_food or out_of_bounds)
end

def new_food(food, snake, dimensions)
  fruit = generate_fruit(dimensions)
  until fruit_position_valid?(fruit, food, snake, dimensions)
    fruit = generate_fruit(dimensions)
  end
  fruit
end

def obstacle_ahead?(snake, direction, dimensions)
  next_head = get_next_head_position(snake, direction)
  ate_self = snake.include?(next_head)

  out_of_bounds?(*next_head, dimensions) or ate_self
end

def danger?(snake, direction, dimensions)
  dead_on_first_move = obstacle_ahead?(snake, direction, dimensions)
  moved_snake = move(snake, direction)
  dead_on_second_move = obstacle_ahead?(moved_snake, direction, dimensions)

  dead_on_first_move or dead_on_second_move
end