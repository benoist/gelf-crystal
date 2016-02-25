module GELF
  # There are two things you should know about log levels/severity:
  #  - syslog defines levels from 0 (Emergency) to 7 (Debug).
  #    0 (Emergency) and 1 (Alert) levels are reserved for OS kernel.
  #  - Ruby default Logger defines levels from 0 (DEBUG) to 4 (FATAL) and 5 (UNKNOWN).
  #    Note that order is inverted.
  # For compatibility we define our constants as Ruby Logger, and convert values before
  # generating GELF message, using defined mapping.

  LOGGER_MAPPING = {
    ::Logger::DEBUG   => 7, # Debug
    ::Logger::INFO    => 6, # Info
    ::Logger::WARN    => 5, # Notice
    ::Logger::ERROR   => 4, # Warning
    ::Logger::FATAL   => 3, # Error
    ::Logger::UNKNOWN => 1,
  } # Alert – shouldn't be used
end
