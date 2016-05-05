require "curses"


class GameOfLife
  include Curses


  class Cell
    attr_accessor :x_pos, :y_pos, :neighbors 
   def id
     @x_pos.to_s +  ":" + @y_pos
   end
  
  end
  #set=Set.new
  #set.add(Cell.new(0,0))
  #set.exists?(Cell.new(0,0).id)
  
  attr_accessor :current_turn, :board, :seeded

  def initialize(size, pat, zeros)

    ## start turn and create board
    @current_turn = 0
    @board = create_board(size)
    @exit = false
    place_piece(size, pat, zeros)


    ## From Curses reference page to capture kill signal
    for i in %w[HUP INT QUIT TERM]
    if trap(i, "SIG_IGN") != 0 then  # 0 for SIG_IGN
    trap(i) {|sig| onsig(sig) }
    end
    end
  end


  ## Used to Start Curses library and animation of GOL
  def start
    init_screen
    crmode
    setpos 0,0
   
    ## Start main loop of GOL update pieces, clear the board, replace new board, and sleep
    while true
    updateboard
    clear
    addstr(outboard)
    refresh
    sleep(0.25)
    break if @exit
    end
  end
  
  ## Still part of Curses code in initialize
  def onsig(sig)
    close_screen
    @exit = true
  end


  ## Simpler animation method friendly in testing framework
  def nocurses
    while true
    updateboard
    puts outboard
    sleep(0.5)
    answer = gets
    break if answer.chomp == 'e'
    end
  end

  ## Scan through board, test neighbors and generate new board placements
  def updateboard
   #scan through 
   board_temp = []
   (0...@board.length).each do |iy|
      new_row = []
      (0...@board[iy].length).each do |ix|

      ## Following rules of Conway's GOL
      val = case neighbors([iy,ix])
        when 0, 1
          0
        when 2
          @board[iy][ix]
        when 3 
          1
        when 4,5,6,7,8
          0 
        end
      new_row << val
      end
    board_temp << new_row
   end
   ## Replace board with new board, decided to use a new board because its 
   ## confusing to update the existing board when considering neighbors
   @board = board_temp
  end

  ## Evaluate Neighbors of specific location
  ## Make sure you don't evaluate off the edge of the board
  ## Return the neighbor count
  def neighbors(location)
   y , x = location
   count = 0
   #upper left
   count += @board[y-1][x-1] if (y-1 >= 0 && x-1 >= 0)
   #upper middle 
   count += @board[y-1][x] if (y-1 >= 0)
   #upper right 
   count += @board[y-1][x+1] if (y-1 < @board.length && x+1 < @board[0].length)
   #middle left 
   count += @board[y][x-1] if (x-1 >= 0)
   #middle right 
   count += @board[y][x+1] if (x+1 < @board[0].length)
   #bottom left 
   count += @board[y+1][x-1] if (y+1 < @board.length && x-1 >= 0)
   #bottom middle 
   count += @board[y+1][x] if (y+1 < @board.length)
   #bottom left 
   count += @board[y+1][x+1] if (y+1 < @board.length && x+1 < @board[0].length)
   
   count
  end
  
  ## Generate Visually friendly version of board
  def outboard
    out = ""
    (0...@board.length).each do |i|
      out +=  @board[i].map {|b| b == 1 ? " X " : "   "}.join("") + "\n"
    end
    out
  end

  ## Generate selected square size of board, Assumption is that the board is a perfect square of differing lengths
  def create_board(size)
    return (0...size).map{|b| (0...size).map{|bb| 0}}
  end

  ## Randomize the starting point of the starting pattern
  ## zeros flag will hold the starting point to the 0,0 point
  def generate_seed(size, pat, zeros = nil)
    @seeded ||= nil
    y = size - pat.length 
    x = size - pat[0].length
    if zeros.nil?
    @seeded = [(rand * x).floor, (rand * y).floor] if @seeded.nil?
    else
    @seeded = [0,0] if @seeded.nil?
    end
  end

private

  ## Initialization method to place starting pattern at the starting point 
  def place_piece(size, pat, zeros)
    x, y = generate_seed(size, pat, zeros)# if x.nil? || y.nil?
    if !@board.nil?
     pat.each_with_index do |paty, indexy|
      paty.each_with_index do |patx, indexx| 
        @board[y+indexy][x+indexx] = pat[indexy][indexx] 
       end
     end
    end
  end
end


if __FILE__ == $0
require 'pry'
require 'minitest/autorun'

class TestGameOfLife < Minitest::Test
def setup
  pat = [[1,1,1,1,1,1,1,1,1,1]]
  @size = 60
  @gol = GameOfLife.new(@size, pat, nil)
end

def test_create_board
  assert_equal @size , @gol.board.length
  assert_equal @size , @gol.board[0].length
end

def test_place_seeds
  assert !@gol.seeded.nil?
end

def test_view_board
  @gol.start
  #@gol.nocurses
end

def test_updateboard
  assert !@gol.updateboard.nil?
end

def test_neighbors
  #Assumption is that seed position is 0,0
  #puts "[0,0] neighbors are : " + @gol.neighbors([0,0]).to_s
  #puts "[1,1] neighbors are : " + @gol.neighbors([1,1]).to_s
  #assert_operator @gol.neighbors([0,0]), :>, 0
end
 


end
end
