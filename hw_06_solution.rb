module TurtleGraphics
  DIRECTIONS = {
    right: [1, 0],
    down: [0, 1],
    left: [-1, 0],
    up: [0, -1]
  }.freeze

  class Turtle
    def initialize(width, height)
      @width = width
      @height = height
      @canvas = Array.new(height) { Array.new(width) { 0 } }

      spawn_at(0, 0)
      @orientation = :right
    end

    def draw(canvas = nil, &block)
      instance_eval(&block) if block_given?
      @canvas = canvas.convert(@canvas) if canvas
      @canvas
    end

    def move
      @x = (@x + DIRECTIONS[@orientation].first) % @width
      @y = (@y + DIRECTIONS[@orientation].last) % @height
      @canvas[@y][@x] += 1
    end

    def turn_left
      index_of_left_direction = (DIRECTIONS.keys.index(@orientation) - 1) % 4
      @orientation = DIRECTIONS.keys[index_of_left_direction]
    end

    def turn_right
      index_of_right_direction = (DIRECTIONS.keys.index(@orientation) + 1) % 4
      @orientation = DIRECTIONS.keys[index_of_right_direction]
    end

    def spawn_at(row, column)
      @x = column
      @y = row
      @canvas[@y][@x] += 1
    end

    def look(orientation)
      @orientation = orientation
    end
  end

  module Canvas
    class ASCII
      def initialize(characters)
        @characters = characters
      end

      def convert(canvas)
        max_steps_on_cell = canvas.map { |row| row.max }.max.to_f
        canvas.map do |row|
          row.map do |col|
            intensity = (col.to_f / max_steps_on_cell)
            char_index = (intensity / (1.0 / (@characters.size - 1))).floor
            @characters[char_index]
          end
        end
      end
    end

    class HTML
      def initialize(physical_pixel_size)
        @physical_pixel_size = physical_pixel_size
      end

      def convert(canvas)
        html = %{<!DOCTYPE html>
<html>
<head>
  <title>Turtle graphics</title>

  <style>
    table {
      border-spacing: 0;
    }

    tr {
      padding: 0;
    }

    td {
      width: #{@physical_pixel_size}px;
      height: #{@physical_pixel_size}px;

      background-color: black;
      padding: 0;
    }
  </style>
</head>
<body>
  <table>
}
        max_steps = canvas.map { |row| row.max }.max.to_f
        canvas.each do |row|
          html += "<tr>\n"
          row.each do |col|
            html += "<td style=\"opacity: #{(col.to_f / max_steps).round(2)}\"></td>"
          end
          html += "</tr>\n"
        end
        html += %{
  </table>
</body>
</html>
}
      end
    end
  end
end

ascii_canvas = TurtleGraphics::Canvas::ASCII.new([' ', '-', '=', '#'])
ascii = TurtleGraphics::Turtle.new(3, 3).draw(ascii_canvas) do
  move
  turn_right
  move
  turn_left
  move
end
p ascii