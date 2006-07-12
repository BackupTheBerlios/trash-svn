class ConnectionList
  def initialize
    @connections = Hash.new
  end

  def add(connection)
  end
end

# Container class for connection attributes.
class Connection
  attr_reader :remote_host, :remote_port, :socket, :thread

  def initialize(remote_host, remote_port, socket = nil)
    @socket = socket ? socket: TCPSocket.new(remote_host, remote_port)
    @remote_host = remote_host
    @remote_port = remote_port
    @thread = TrashThread.new(@socket)
  end

  def close
    @socket.close
  end
end
