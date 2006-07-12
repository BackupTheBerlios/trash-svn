module TrashConf
  @@block_size = 1024*512
  @max_up = 200
  @@port = 1112
  @@crypt = false

  def TrashConf.block_size
    return @@block_size
  end

  def TrashConf.port
    return @@port
  end
end


