# TrashMain.rb
# Andrew Muro <andrewdangermuro@gmail.com>
# 2006/07/18

require 'socket'
require 'thread'
require 'rubygems'
require 'readline'
include Readline

require 'TrashConf'
require 'TrashBag'
require 'TrashConnect'
require 'TrashMain'

# The actual TRASH client.
class TrashClient
  def initialize(crypt = nil)
    @connections = ConnectionList.new
    @conf = TrashConf.new

    # Start listening for incoming connections not on localhost. This needs to be fixed.
    local_ip = `ifconfig | grep 'inet\ addr:'`.scan(/inet\ addr:(\d+\.\d+\.\d+\.\d+)\ \ /).flatten![0]
    @server = TCPServer.new(local_ip,@conf.port)

    prompt
  end

  # Print configuration options.
  def conf
    @conf.conf
  end

  # Print current connection status.
  def status
    @connections.status
  end

  # Close all connections (currently only used before an exit).
  def close_all
    @connections.close_all
  end

  # Connect to a remote host.
  # args: host, port
  def connect(args)
    if (args.size != 2)
      puts "usage: connect [host] [port]"
      return
    else
      @connections.add(args[0], args[1])
      puts "connected to #{args[0]}:#{args[1]}"
    end
  end
  
  # Listen for remote connections.
  def listen
    Thread.new do
      while (true)
        socket = @server.accept
        puts "connection from #{socket.peeraddr[2]} port #{socket.peeraddr[1]}"
        @connections.add(socket.peeraddr[2], socket.peeraddr[1], socket)
      end
    end
  end

  # Send a chat message to a remote client.
  # args: host, message
  def message(args)
    if (args.size != 2)
      puts "usage: message [host] [message]"
      return
    else
      @connections[args[0]].send(TrashBag.new(args[1]))
    end
  end

  # Display interaction prompt.
  def prompt
    listen

    while (true)
      args = readline("trash> ", true).chomp.split(/ /)
      command = args.shift
      
      case command
      when "connect"
        connect(args)
      when "message"
        message(args)
      when "disconnect"
        disconnect(args)
      when "status"
        status
      when "config"
        conf
      when "exit"
        close_all
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

  # Displays command help.
  def display_help
    puts """
commands:
--------
connect [host] [port] - connect to a remote trash client
message [host] [message] - send a chat message to a remote trash client
browse [host] - browse a remote host's files
disconnect [host] - disconnect from a remote host
status - display current connections
config - print trash configuration
exit - talk to my ass
--------

"""
  end
end

# Used to listen for incoming chat/file requests.
class TrashThread
  def initialize(socket)
    @socket = socket
    listen
  end

  # Listens for an incoming connection.
  def listen
    @thread = Thread.new do
      while (true)
        header = @socket.read(1)
        length = @socket.read(4).unpack("I")[0]
        data = @socket.read(length)

        case header
        when "0"
          puts "chat message from #{@socket.peeraddr[3]}: #{data}"
        end
      end
    end
  end
end
