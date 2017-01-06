# frozen_string_literal: true

module Twenty48
  #
  # Utilities for calling the xxd utility on states.
  #
  # The man page seems to imply that we can pass an output file name, but it
  # does not seem to actually work, so we use shell redirects here instead.
  #
  module XxdStates
    module_function

    # Size of a state on disk in binary format, in bytes.
    STATE_SIZE = 8

    #
    # Convert from binary to hexadecimal binary.
    #
    def xxd(bin_pathname, xxd_pathname, remove: true)
      system <<-CMD
        xxd -plain -cols #{STATE_SIZE} <#{bin_pathname} >#{xxd_pathname}
      CMD
      raise 'xxd failed' unless $CHILD_STATUS.exitstatus == 0
      FileUtils.rm bin_pathname if remove
    end

    #
    # Convert back from hexadecimal bytes to binary.
    #
    def revert_xxd(xxd_pathname, bin_pathname, remove: true)
      system <<-CMD
        xxd -revert -plain -cols #{STATE_SIZE} <#{xxd_pathname} >#{bin_pathname}
      CMD
      raise 'xxd revert failed' unless $CHILD_STATUS.exitstatus == 0
      FileUtils.rm xxd_pathname if remove
    end
  end
end
