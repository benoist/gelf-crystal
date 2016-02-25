require "./spec_helper"

class UDPListener
  def self.listen
    yield new
  end

  def initialize
    @server = UDPSocket.new(Socket::Family::INET6)
    @server.bind("::", 0)
  end

  def port
    @server.addr.ip_port
  end

  def logger
    @logger ||= GELF::Logger.new("localhost", port, "WAN").configure do |config|
      config.facility = "gelf-cr"
      config.host     = "localhost"
    end
  end

  def read_buffer
    slice = Slice(UInt8).new(1432)
    @server.read(slice)
    slice
  end

  def get_json
    slice   = read_buffer
    io      = MemoryIO.new(slice)
    inflate = Zlib::Inflate.new(io)
    str     = String::Builder.build do |builder|
      IO.copy(inflate, builder)
    end
    JSON.parse(str)
  end
end

describe GELF do
  it "sends messages over a udp socket" do
    UDPListener.listen do |listener|
      listener.logger.debug("test")

      listener.get_json["short_message"].should eq "test"
    end
  end

  it "splits up large messages" do
    UDPListener.listen do |listener|
      listener.logger.debug((1..1200).to_a.to_s)

      slice = listener.read_buffer
      slice[0, 2].should eq Slice(UInt8).new(UInt8[0x1e, 0x0F].to_unsafe, 2)
      message_id = slice[2, 8]
      slice.at(10).should eq 0 # index
      slice.at(11).should eq 2 # num

      data1 = slice + 12

      slice = listener.read_buffer
      slice[0, 2].should eq Slice(UInt8).new(UInt8[0x1e, 0x0F].to_unsafe, 2)
      slice.at(10).should eq 1 # index
      slice.at(11).should eq 2 # num

      message_id.should eq slice[2, 8]

      data2 = slice + 12

      io = MemoryIO.new
      io.write(data1)
      io.write(data2)
      io.rewind

      inflate = Zlib::Inflate.new(io)
      str     = String::Builder.build do |builder|
        IO.copy(inflate, builder)
      end
      JSON.parse(str)["short_message"].should eq (1..1200).to_a.to_s
    end
  end

  it "sets the default values" do
    UDPListener.listen do |listener|
      listener.logger.debug("test")

      json = listener.get_json

      json["version"].should eq "1.1"
      json["host"].should eq "localhost"
      json["level"].should eq GELF::LOGGER_MAPPING[GELF::Severity::DEBUG]
      json["short_message"].should eq "test"
      json["_facility"].should eq "gelf-cr"
      json["timestamp"]
    end
  end

  it "has severity method" do
    UDPListener.listen do |listener|
      listener.logger.debug("test")
      listener.get_json["level"].should eq 7
      listener.logger.info("test")
      listener.get_json["level"].should eq 6
      listener.logger.warn("test")
      listener.get_json["level"].should eq 5
      listener.logger.error("test")
      listener.get_json["level"].should eq 4
      listener.logger.fatal("test")
      listener.get_json["level"].should eq 3
      listener.logger.unknown("test")
      listener.get_json["level"].should eq 1
    end
  end

  it "allows logging with extra parameters" do
    UDPListener.listen do |listener|
      listener.logger.debug({ "short_message" => "test", "_extra_var" => 10 })
      json = listener.get_json
      json["short_message"].should eq "test"
      json["_extra_var"].should eq 10
    end
  end

  it "allows loggin with a block" do
    UDPListener.listen do |listener|
      listener.logger.debug { "test" }
      listener.get_json["short_message"].should eq "test"
    end
  end

  it "logs a default short_message when missing" do
    UDPListener.listen do |listener|
      listener.logger.debug({ "_extra_var" => 10 })
      json = listener.get_json
      json["short_message"].should eq "Message must be set!"
      json["_extra_var"].should eq 10
    end
  end

end
