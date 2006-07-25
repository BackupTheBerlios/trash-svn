#!/usr/bin/env ruby

class CmdInterpreterError < String
end

def parse_input(text)
  splitted = text.split(/ /)

  args = []
  pos = 0
  quotes = nil
  
  curr_arg = ''

  while (text != '')
    char = text[pos, 1]

    quotes = char =~ /['"]/

    space = char =~ / /

    pos += 1
  end
  
end

while true
  print "prompt> "

  line = gets.chomp

  parse_input(line).each { |a| puts "arg: #{a}" }
  
end

