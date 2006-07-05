#!/usr/bin/ruby

require 'socket'
require 'thread'
require 'aes'
require 'Constants'
require 'rubygems'
require 'progressbar'

# deps: aes, rubygems, progressbar
# need to threadify this.

class Connection
  attr_reader :remote_host, :remote_port, :socket

  def initialize(remote_host, remote_port, username = nil)
    @socket = TCPSocket.new(remote_host, remote_port)
    @remote_host = remote_host
    @remote_port = remote_port
    @username = username
  end
end

class TCPSocket
  def write_throttle(data)
    pre = Time.now
    self.write(data)
    post = Time.now

    speed = ($block_size/(post.to_f - pre.to_f))/1024
    p "#{speed} KB/s"
    #p "#{($block_size.to_f/time)/1024} KB/s"
    if (speed > $max_up)
      puts "delay..."
      sleep 1
    end
    #puts "%.1f" % ($block_size.to_f/time)/1024
  end
end

class TrashClient
  attr_reader :server, :connections

  def initialize(crypt = nil)
    @connections = Hash.new

    # Init encryption, if specified.
    if (crypt)
      print "enter key (16 characters): "
      while ((@key = $stdin.gets.chomp!).size != 16)
        print "enter key (16 characters): "
      end
      
      @cipher = AES.new
      @cipher.cfb_salt(@key)
    end

    # Start listening for incoming connections.
    local_ip = `ifconfig | grep 'inet\ addr:'`.scan(/inet\ addr:(\d+\.\d+\.\d+\.\d+)\ \ /).flatten![0]
    @server = TCPServer.new(local_ip,$port)
  end

  # Connect to a remote host.
  def remote_connect(remote_port = nil)
    print "remote host: "
    remote_host = $stdin.gets.chomp!

    unless (remote_port)
      print "remote port: "
      remote_port = $stdin.gets.chomp!
    else
      remote_port = $port
    end

    @connections[remote_host] = Connection.new(remote_host, remote_port)
    puts "connected to #{remote_host}:#{remote_port}"
  end

  def disconnect
    print "enter remote host: "
    remote_host = $stdin.gets.chomp!
    if (@connections[remote_host])
      @connections[remote_host].socket.close
      @connections.delete(remote_host)
    else
      puts "invalid connection: #{remote_host}"
    end
  end

  # Send file to remote host.
  def send_file(file = nil)
    print "enter remote host: "
    remote_host = $stdin.gets.chomp!
    unless (@connections[remote_host])
      puts "invalid connection: #{remote_host}"
      return
    else
      socket = @connections[remote_host].socket
    end

    unless (file)
      print "filename: "
      file = $stdin.gets.chomp!
    end

    puts "sending file: #{file}"
#    pbar = ProgressBar.new(file,File.stat(file).size/$block_size)

    File.open(file,"r") do |f|
      while (chunk = f.read($block_size))

        # Encrypt data if specified.
        if (@crypt)
          cipher_data = @cipher.cfb_encrypt(chunk)
#          socket.write(cipher_data)
          socket.write_throttle(cipher_data)
        else
#          socket.write(chunk)
          socket.write_throttle(chunk)
        end
 #       pbar.inc
      end
    end
 #   pbar.finish
  end

  # Displays the current connections and identifiers. This is
  # going to change to usernames eventually.
  def connection_status
    if (@connections.size == 0)
      puts "no connections."
    else
      @connections.each_value do |conn|
        puts "#{conn.remote_host}:#{conn.remote_port}"
      end
    end
  end
end

def main_loop
  t = TrashClient.new(false)

  print "trash> "
  while ((command = $stdin.gets.chomp!) != "exit")
    case command
    when "remote_connect"
      t.remote_connect
    when "send_file"
      t.send_file
    when "help"
      puts """commands:
remote_connect - connect to a remote trash client
send_file - send a file to a remote trash client
connection_status - display current connections
send_message - send a message to remote trash client
disconnect - disconnect from a remote client
exit - talk to my ass"""
    when "connection_status"
      t.connection_status
    else
      puts "invalid command ('help' works)"
    end
    print "trash> "
  end
end

main_loop
