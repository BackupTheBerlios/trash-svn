class TrashBag
end

# Represents a chat message between clients.
class TrashTalk < TrashBag
  def initialize(message)
    @message = message
    @length = message.size
    @header = "0"
  end
end

class TrashFile < TrashBag
  def initialize(file)
    @file = file
    @length = FileTest.size(file)
    @header = "1"
  end
end
