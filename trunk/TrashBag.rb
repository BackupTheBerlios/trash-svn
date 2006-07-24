# TrashBag.rb
# Andrew Muro <andrewdangermuro@gmail.com>
# 2006/07/18

# TRASH packet superclass.
class TrashBag
  attr_reader :header,:length,:data

  # Constructor is given an object which it then converts to a TrashBag.
  def initialize(data)

    # Chat message.
    if (data.class == String)
      @header = "0"
      @length = data.size
      @data = data

      # File.
    elsif (data.class == File)
      @header = "1"
      @length = FileTest.size(data)
      @data = data
    end
  end
end
