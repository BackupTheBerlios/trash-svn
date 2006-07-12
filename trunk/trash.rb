#!/usr/bin/ruby

require 'socket'
require 'thread'
require 'rubygems'
require 'TrashConf'
require 'TrashBag'
require 'TrashConnect'
require 'TrashMain'

# Displays help menu.
def display_help
  puts """
commands:
--------
connect [host] [port] - connect to a remote trash client
message [host] [message] - send a chat message to a remote trash client
browse [host] - browse a remote host's files
disconnect [host] - disconnect from a remote host
status - display current connections
exit - talk to my ass
--------"""
end

def main_loop
  t = TrashClient.new(false)
  t.listen

  while (true)
    print "trash> "
    $stdout.flush
    args = $stdin.gets.chomp!.split(/ /)
    command = args.shift

    case command
    when "connect"
      t.connect(args)
    when "message"
      t.message(args)
    when "disconnect"
      t.disconnect(args)
    when "status"
      t.status
    when "exit"
      t.close_all
      exit 0
    when "help"
      display_help
    when nil
      next
    else
      puts "invalid."
    end
  end
end

main_loop
