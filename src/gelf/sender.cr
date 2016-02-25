module GELF
  # Plain Ruby UDP sender.
  class UdpSender
    def initialize(host, port)
      @client = UDPSocket.new
      @client.connect host, port
    end

    def write(slice)
      @client.write(slice)
    end

    def close
      @client.close
    end
  end
end
