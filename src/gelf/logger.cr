module GELF
  class Logger
    alias HashType = Hash(String, (String | Int::Signed | Int::Unsigned | Float64 | Bool))
    alias MessageType = (Hash(String, (String | Int::Signed | Int::Unsigned | Float64 | Bool)) | String)

    property! :facility
    property! :host
    property! :level

    def initialize(host, port, @max_size = :wan)
      @sender = UdpSender.new(host, port)
      @level = Severity::INFO
    end

    def max_chunk_size
      case @max_size
      when :lan
        8154
      else
        1420
      end
    end

    def configure
      yield(self)
      self
    end

    {% for level in ["DEBUG", "INFO", "WARN", "ERROR", "FATAL", "UNKNOWN"] %}
      def {{level.id.downcase}}(message : HashType, progname = nil : String?)
        add(GELF::Severity::{{level.id}}, message, progname)
      end

      def {{level.id.downcase}}(message : String, progname = nil : String?)
        add(GELF::Severity::{{level.id}}, message, progname)
      end

      def {{level.id.downcase}}(progname = nil : String?)
          add(GELF::Severity::{{level.id}}, yield, progname)
      end

      def {{level.id.downcase}}?
        GELF::Severity::{{level.id}} >= level
      end
    {% end %}

    private def add(level, message : Hash(String, (String | Int::Signed | Int::Unsigned | Float64 | Bool)), progname = nil : String?)
      notify_with_level(level, message.merge({"_facility" => progname || facility}))
    end

    private def add(level, message : String, progname = nil : String?)
      hash = {} of String => (String | Int::Signed | Int::Unsigned | Float64 | Bool)
      hash["short_message"] = message
      add(level, hash, progname)
    end

    private def notify_with_level(level, message : Hash(String, (String | Int::Signed | Int::Unsigned | Float64 | Bool)))
      return unless level >= @level

      message["version"] = "1.1"
      message["host"] = host
      message["level"] = GELF::LOGGER_MAPPING[level]
      message["timestamp"] = "%f" % Time.now.epoch_f
      message["short_message"] ||= "Message must be set!"

      data = serialize_message(message)

      if data.size > max_chunk_size
        msg_id = SecureRandom.hex(4)
        num_slices = (data.size / max_chunk_size.to_f).ceil.to_i

        num_slices.times do |index|
          io = MemoryIO.new

          # Magic bytes
          io.write_byte(0x1e_u8)
          io.write_byte(0x0F_u8)

          # Message id
          io.write(msg_id.to_slice)

          # Chunk info
          io.write_byte(index.to_u8)
          io.write_byte(num_slices.to_u8)

          # Bytes
          bytes_to_send = [data.size, max_chunk_size].min
          io.write(data[0, bytes_to_send])
          data += bytes_to_send

          @sender.write(io.to_slice)
        end
      else
        @sender.write(data)
      end
    end

    private def serialize_message(message)
      io = MemoryIO.new
      deflater = Zlib::Deflate.new(io)
      json = message.to_json
      deflater.print(json)
      deflater.close
      io.to_slice
    end
  end
end
