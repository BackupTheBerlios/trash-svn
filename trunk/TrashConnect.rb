# TrashConnect.rb
# Andrew Muro <andrewdangermuro@gmail.com>
# 2006/07/18

# List of remote connections. Just a Hash wrapper.
class ConnectionList
  def initialize
    @connections = Hash.new
  end

  # Add a remote connection to the list.
  def add(remote_host, remote_port, socket = nil)
    @connections[remote_host] = Connection.new(remote_host, remote_port, socket)
  end

  # Remove (and disconnect) a remote host.
  def remove(remote_host)
    @connections[remote_host].close
    @connections.delete(remote_host)
  end

  # Close all connections and remove all entries.
  def close_all
    @connections.each_key do |remote_host|
      @connections[remote_host].close
      @connections.delete(remote_host)
    end
  end

  # Display current remote connection status.
  def status
    puts
    puts "current connections:"
    puts "-------------------"
    @connections.each_value do |conn|
      puts "#{conn.remote_host}:#{conn.remote_ports[0]}/#{conn.remote_ports[1]}"
    end
    puts
  end

  # Yup.
  def [](key)
    return @connections[key]
  end
end

# Container class for connection attributes.
class Connection
  attr_reader :remote_host, :remote_ports, :socket

  def initialize(remote_host, remote_port, socket = nil)

    # On an incoming connection, use the socket already created from the connecting
    # host. Otherwise create a new messaging socket. For both cases, create a new socket
    # for sending files.
    @chat_socket = socket ? socket: TCPSocket.new(remote_host, remote_port)
#    @file_socket = TCPSocket.new(remote_host, remote_port)

    @remote_host = @chat_socket.peeraddr[2]
    @remote_ports = [@chat_socket.peeraddr[1],@chat_socket.peeraddr[1]]

    # Start a thread for listening on the new sockets.
    @chat_thread = TrashThread.new(@chat_socket)
#    @file_thread = TrashThread.new(@file_socket)
  end

  # Close the connection.
  def close
    @chat_socket.close
#    @file_socket.close
  end

  # Send a TrashBag to a remote client.
  def send(tbag)
    socket = (tbag.header == "0") ? @chat_socket: @file_socket
    socket.write(tbag.header)
    socket.write([tbag.length].pack("I"))
    socket.write(tbag.data)
  end
end
