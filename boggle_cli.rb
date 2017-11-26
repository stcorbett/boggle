require_relative 'boggle'

class BoggleCli
  def initialize(board:, speed:, start_time:)
    self.board          = board
    self.word           = []
    self.words          = []
    self.start          = start_time
    self.speed          = speed
    self.over           = false
    self.time_allowed   = 60 * 3
    self.char_locations = chars_to_locations board
    update_time start_time
  end

  attr_accessor :board, :char_locations, :word, :words
  attr_accessor :start, :speed, :time_allowed, :now, :time_left, :over

  alias over? over

  # returns true if this changes what would be drawn
  def add_input(char)
    if quit? char
      self.over = true
      true
    elsif submit_guess? char
      matches = matches(word, char_locations)
      words << word if matches.any? && !words.include?(word)
      self.word = []
      true
    elsif word.last == "Q" && (char == "u" || char == "U")
      word.last << "u"
      true
    elsif delete? char
      word.last == 'Qu' ?  word[-1] = 'Q' : word.pop
      true
    elsif guess? char
      word << char.upcase
      true
    else
      false
    end
  end

  def hide_cursor
    "\e[?25l"
  end

  def show_cursor
    "\e[?25h"
  end

  # returns true if this changes what would be drawn
  def update_time(time)
    prev_time_left   = time_left
    prev_over        = over

    self.now         = time
    seconds          = now - start
    time_passed      = (speed * seconds).to_i
    self.time_left   = time_allowed - time_passed
    self.over        = true if time_left < 0 # allow 1s grace :)
    self.time_left   = 0    if time_left < 0 # but report it as still being at zero

    prev_over != over || prev_time_left != time_left
  end


  def to_s(winsize)
    # build up the board
    to_print = ""

    # clear screen
    to_print << "\e[H\e[2J"

    # print the time
    to_print << "\e[1;14HTime:  #{time_colour}%d\e[0m   " % time_left

    # print the number of words found
    to_print << "\e[2;14HWords: #{words.length}"

    # print the score
    score = words.reduce(0) { |score, word| score + word_score(word) }
    to_print << sprintf("\e[3;14HScore: %d", score)

    # find matches
    matches = matches(word, char_locations)

    # print the board
    to_print << show_board(
      board,
      Set.new(matches.flatten 1),
      Set.new(matches.map &:last),
    )

    # print the word
    if matches.any? || word.empty?
      to_print << "\e[92m" # bright green
    else
      to_print << "\e[91m" # bright red
    end
    to_print << "\r\n" << "> " << word.join.downcase << "\e[0m\r\n" << "\r\n"

    # print the words
    cols, rows = winsize
    cols -= 7 # for the stuff previously printed
    xoffset = 1
    words.each_slice(cols) do |word_set|
      max_score = 0
      word_set.each.with_index(8) do |word, yoffset|
        score = word_score(word)
        max_score = score if max_score < score
        to_print << "\e[#{yoffset};#{xoffset}H%2d #{word.join.downcase}" % score
      end
      xoffset += max_score.to_s.length
      xoffset += word_set.map(&:length).max + 3 # for the gap between words
    end

    to_print
  end

  def final_screen(winsize)
    to_s(winsize) << "\r\n\n\e[41;97m GAME OVER!! \e[0m\e[J\r\n"
  end

  def time_colour
    colour = 92                    # green
    colour = 93 if time_left <= 30 # yellow/orange
    colour = 91 if time_left <= 10 # red
    "\e[#{colour}m"
  end
end