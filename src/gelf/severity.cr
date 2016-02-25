module GELF
  # There are two things you should know about log levels/severity:
  #  - syslog defines levels from 0 (Emergency) to 7 (Debug).
  #    0 (Emergency) and 1 (Alert) levels are reserved for OS kernel.
  #  - Ruby default Logger defines levels from 0 (DEBUG) to 4 (FATAL) and 5 (UNKNOWN).
  #    Note that order is inverted.
  # For compatibility we define our constants as Ruby Logger, and convert values before
  # generating GELF message, using defined mapping.

  enum Severity
    DEBUG
    INFO
    WARN
    ERROR
    FATAL
    UNKNOWN
  end

  LOGGER_MAPPING = {
    Severity::DEBUG   => 7, # Debug
    Severity::INFO    => 6, # Info
    Severity::WARN    => 5, # Notice
    Severity::ERROR   => 4, # Warning
    Severity::FATAL   => 3, # Error
    Severity::UNKNOWN => 1,
  } # Alert – shouldn't be used
end
