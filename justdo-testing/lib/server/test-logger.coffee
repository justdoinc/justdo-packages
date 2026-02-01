# test-logger.coffee
# Centralized logger for test output - Meteor server side
#
# Writes test-related logs to the file specified by TEST_LOG_FILE env var.
# This separates test output (fixtures, manifests, test results) from
# regular server noise for easier debugging and AI parsing.
#
# Usage:
#   TestLogger.log "[TestFixtures]", "Seeding users..."
#   TestLogger.warn "[TestManifest]", "Overwriting manifest"
#   TestLogger.error "[TestFixtures]", "Failed to seed"
#
# Log format:
#   [ISO_TIMESTAMP] [LEVEL] [PREFIX] message

fs = Npm.require("fs")

TestLogger =
  _logFile: process.env.TEST_LOG_FILE or null
  _stream: null
  
  # Get or create the write stream
  # @return [WriteStream|null] The write stream, or null if no log file
  _getStream: ->
    return @_stream if @_stream?
    return null unless @_logFile
    
    try
      @_stream = fs.createWriteStream(@_logFile, { flags: "a" })
    catch err
      console.error "[TestLogger] Failed to open log file: #{err.message}"
      @_logFile = null
      return null
    
    return @_stream
  
  # Internal write method
  # @param level [String] Log level (INFO, WARN, ERROR)
  # @param prefix [String] Log prefix (e.g., "[TestFixtures]")
  # @param message [String] Log message
  _write: (level, prefix, message) ->
    timestamp = new Date().toISOString()
    line = "[#{timestamp}] [#{level}] #{prefix} #{message}"
    
    stream = @_getStream()
    if stream
      stream.write(line + "\n")
    else
      # Fallback to console if no log file configured
      # This maintains backward compatibility when not using test log separation
      switch level
        when "ERROR" then console.error(line)
        when "WARN" then console.warn(line)
        else console.log(line)
  
  # Log info message
  # @param prefix [String] Log prefix (e.g., "[TestFixtures]")
  # @param message [String] Log message
  log: (prefix, message) ->
    @_write("INFO", prefix, message)
  
  # Log warning message
  # @param prefix [String] Log prefix
  # @param message [String] Log message
  warn: (prefix, message) ->
    @_write("WARN", prefix, message)
  
  # Log error message
  # @param prefix [String] Log prefix
  # @param message [String] Log message
  error: (prefix, message) ->
    @_write("ERROR", prefix, message)
  
  # Check if logging to file is enabled
  # @return [Boolean] True if TEST_LOG_FILE is set
  isEnabled: ->
    @_logFile?

# Make globally available
@TestLogger = TestLogger
