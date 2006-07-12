class TrashClient
  attr_reader :server, :connections

  def initialize(crypt = nil)
    @connections = Hash.new

    # Start listening for incoming connections. This needs to be fixed.
    local_ip = `ifconfig | grep 'inet\ addr:'`.scan(/inet\ addr:(\d+\.\d+\.\d+\.\d+)\ \ /).flatten![0]
    @server = TCPServer.new(local_ip,$port)
  end

  # Connect to a remote host.
  def connect(args)
    if (args.size != 2)
      puts "usage: connect [host] [port]"
      return
    else
      @connections[args[0]] = Connection.new(args[0],args[1])
      puts "connected to #{args[0]}:#{args[1]}"
    end
  end
  
  # Disconnect from a remote host.
  def disconnect(args)
    if (args != 1)
      puts "usage: disconnect [host]"
    elsif (@connections[args[0]])
      @connections[args[0]].close
    else
      puts "invalid connection."
    end
  end

  # Displays the current connections and identifiers. This is
  # going to change to usernames eventually.
  def status
    if (@connections.size == 0)
      puts "no connections."
    else
      @connections.each_value do |conn|
        puts "#{conn.remote_host}:#{conn.remote_port}"
      end
    end
  end

  # Closes all open connections.
  def close_all
    @connections.each_value do |conn|
      conn.close
    end
  end

  def listen
    Thread.new do
      while (true)
        socket = @server.accept
        puts "connection from #{socket.peeraddr[3]} port #{socket.peeraddr[1]}"
        @connections[socket.peeraddr[3]] = Connection.new(socket.peeraddr[3],socket.peeraddr[1],socket)
      end
    end
  end

  def message(args)
    if (args.size != 2)
      puts "usage: message [host] [message]"
      return
    else
      @connections[args[0]].socket.write("0")
      @connections[args[0]].socket.write([args[1].size].pack("I"))
      @connections[args[0]].socket.write(args[1])
    end
  end
end

class TrashThread
  def initialize(socket)
    @socket = socket
    listen
  end

  def listen
    @thread = Thread.new do
      while (true)
        header = @socket.read(1)
        length = @socket.read(4).unpack("I")[0]
        data = @socket.read(length)
        
        case header
        when "0"
          puts "chat message from #{socket.peeraddr[3]}: #{data}"
        end
      end
    end
  end
end
