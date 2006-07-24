# TrashConf.rb
# Andrew Muro <andrewdangermuro@gmail.com>
# 2006/07/24

# Container class for various TRASH program options.
class TrashConf

  # If no configuration file is given, TRASH looks for "trash.conf" in
  # the current working directory.
  def initialize(cfg = nil)

    # Some default values.
    @conf = {"port" => 1112, "dldir" => "./", "block_size" => 16}

    # Read options from file.
    IO.readlines("trash.conf").each do |value|
      unless (value.chomp.empty?)
        line = value.chomp.split(/=/).collect {|i| i.strip!}
        @conf[line[0]] = (line[1] =~ /[A-Za-z]/) ? line[1]: line[1].to_i
      end
    end
  end

  # Throwaway accessor functions.
  def port
    return @conf["port"]
  end

  def dldir
    return @conf["dldir"]
  end

  def block_size
    return @conf["block_size"]
  end

  # Print configuration paramters.
  def conf
    puts
    puts "trash configuration:"
    puts "-------------------"
    @conf.each_pair do |k, v|
      puts "#{k} = #{v}"
    end
    puts
  end
end

      
