# typed: false

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `timecop` gem.
# Please instead update this file by running `bin/tapioca gem timecop`.

# source://timecop//lib/timecop/time_extensions.rb#31
class Date
  include ::Comparable

  class << self
    # source://timecop//lib/timecop/time_extensions.rb#111
    def closest_wday(wday); end

    # source://timecop//lib/timecop/time_extensions.rb#33
    def mock_date; end

    # source://timecop//lib/timecop/time_extensions.rb#107
    def mocked_time_stack_item; end

    # source://timecop//lib/timecop/time_extensions.rb#85
    def parse(*args); end

    # source://timecop//lib/timecop/time_extensions.rb#85
    def parse_with_mock_date(*args); end

    # source://timecop//lib/timecop/time_extensions.rb#47
    def strptime(str = T.unsafe(nil), fmt = T.unsafe(nil), start = T.unsafe(nil)); end

    # source://timecop//lib/timecop/time_extensions.rb#47
    def strptime_with_mock_date(str = T.unsafe(nil), fmt = T.unsafe(nil), start = T.unsafe(nil)); end

    # source://timecop//lib/timecop/time_extensions.rb#39
    def today; end

    # source://timecop//lib/timecop/time_extensions.rb#39
    def today_with_mock_date; end
  end
end

# source://timecop//lib/timecop/time_extensions.rb#120
class DateTime < ::Date
  class << self
    # source://timecop//lib/timecop/time_extensions.rb#122
    def mock_time; end

    # source://timecop//lib/timecop/time_extensions.rb#165
    def mocked_time_stack_item; end

    # source://timecop//lib/timecop/time_extensions.rb#126
    def now; end

    # source://timecop//lib/timecop/time_extensions.rb#126
    def now_with_mock_time; end

    # source://timecop//lib/timecop/time_extensions.rb#134
    def parse(*args); end

    # source://timecop//lib/timecop/time_extensions.rb#134
    def parse_with_mock_date(*args); end
  end
end

# source://timecop//lib/timecop/time_extensions.rb#172
module Process
  class << self
    # source://timecop//lib/timecop/time_extensions.rb#176
    def clock_gettime(clock_id, unit = T.unsafe(nil)); end

    # source://timecop//lib/timecop/time_extensions.rb#176
    def clock_gettime_mock_time(clock_id, unit = T.unsafe(nil)); end

    private

    # source://timecop//lib/timecop/time_extensions.rb#210
    def mock_time_monotonic; end

    # source://timecop//lib/timecop/time_extensions.rb#215
    def mock_time_realtime; end
  end
end

# source://timecop//lib/timecop/time_extensions.rb#4
class Time
  include ::Comparable

  class << self
    # source://timecop//lib/timecop/time_extensions.rb#6
    def mock_time; end

    # source://timecop//lib/timecop/time_extensions.rb#21
    def new(*args); end

    # source://timecop//lib/timecop/time_extensions.rb#21
    def new_with_mock_time(*args); end

    # source://timecop//lib/timecop/time_extensions.rb#13
    def now; end

    # source://timecop//lib/timecop/time_extensions.rb#13
    def now_with_mock_time; end
  end
end

# Timecop
# * Wrapper class for manipulating the extensions to the Time, Date, and DateTime objects
# * Allows us to "freeze" time in our Ruby applications.
# * Optionally allows time travel to simulate a running clock, such time is not technically frozen.
#
# This is very useful when your app's functionality is dependent on time (e.g.
# anything that might expire).  This will allow us to alter the return value of
# Date.today, Time.now, and DateTime.now, such that our application code _never_ has to change.
#
# source://timecop//lib/timecop/time_stack_item.rb#1
class Timecop
  include ::Singleton
  extend ::Singleton::SingletonClassMethods

  # @return [Timecop] a new instance of Timecop
  #
  # source://timecop//lib/timecop/timecop.rb#198
  def initialize; end

  # source://timecop//lib/timecop/timecop.rb#165
  def baseline; end

  # source://timecop//lib/timecop/timecop.rb#160
  def baseline=(b); end

  # source://timecop//lib/timecop/timecop.rb#233
  def return(&block); end

  # source://timecop//lib/timecop/timecop.rb#248
  def return_to_baseline; end

  # source://timecop//lib/timecop/timecop.rb#173
  def set_baseline(b); end

  # source://timecop//lib/timecop/timecop.rb#190
  def set_stack(s); end

  # source://timecop//lib/timecop/timecop.rb#181
  def stack; end

  # source://timecop//lib/timecop/timecop.rb#209
  def thread_safe; end

  # source://timecop//lib/timecop/timecop.rb#204
  def thread_safe=(t); end

  # @raise [SafeModeException]
  #
  # source://timecop//lib/timecop/timecop.rb#213
  def travel(mock_type, *args, &block); end

  # source://timecop//lib/timecop/timecop.rb#243
  def unmock!; end

  class << self
    # source://timecop//lib/timecop/timecop.rb#84
    def baseline; end

    # source://timecop//lib/timecop/timecop.rb#88
    def baseline=(baseline); end

    # Allows you to run a block of code and "fake" a time throughout the execution of that block.
    # This is particularly useful for writing test methods where the passage of time is critical to the business
    # logic being tested.  For example:
    #
    #   joe = User.find(1)
    #   joe.purchase_home()
    #   assert !joe.mortgage_due?
    #   Timecop.freeze(2008, 10, 5) do
    #     assert joe.mortgage_due?
    #   end
    #
    # freeze and travel will respond to several different arguments:
    # 1. Timecop.freeze(time_inst)
    # 2. Timecop.freeze(datetime_inst)
    # 3. Timecop.freeze(date_inst)
    # 4. Timecop.freeze(offset_in_seconds)
    # 5. Timecop.freeze(year, month, day, hour=0, minute=0, second=0)
    # 6. Timecop.freeze() # Defaults to Time.now
    #
    # When a block is also passed, Time.now, DateTime.now and Date.today are all reset to their
    # previous values after the block has finished executing.  This allows us to nest multiple
    # calls to Timecop.travel and have each block maintain it's concept of "now."
    #
    # The Process.clock_gettime call mocks both CLOCK::MONOTIC and CLOCK::REALTIME
    #
    # CLOCK::MONOTONIC works slightly differently than other clocks. This clock cannot move to a
    # particular date/time. So the only option that changes this clock is #4 which will move the
    # clock the requested offset. Otherwise the clock is frozen to the current tick.
    #
    # * Note: Timecop.freeze will actually freeze time.  This can cause unanticipated problems if
    #   benchmark or other timing calls are executed, which implicitly expect Time to actually move
    #   forward.
    #
    # * Rails Users: Be especially careful when setting this in your development environment in a
    #   rails project.  Generators will load your environment, including the migration generator,
    #   which will lead to files being generated with the timestamp set by the Timecop.freeze call
    #   in your dev environment
    #
    # Returns the value of the block if one is given, or the mocked time.
    #
    # source://timecop//lib/timecop/timecop.rb#57
    def freeze(*args, &block); end

    # Returns whether or not Timecop is currently frozen
    #
    # @return [Boolean]
    #
    # source://timecop//lib/timecop/timecop.rb#131
    def frozen?; end

    # source://timecop//lib/timecop/timecop.rb#145
    def mock_process_clock=(mock); end

    # @return [Boolean]
    #
    # source://timecop//lib/timecop/timecop.rb#149
    def mock_process_clock?; end

    # Reverts back to system's Time.now, Date.today and DateTime.now (if it exists) permamently when
    # no block argument is given, or temporarily reverts back to the system's time temporarily for
    # the given block.
    #
    # source://timecop//lib/timecop/timecop.rb#95
    def return(&block); end

    # source://timecop//lib/timecop/timecop.rb#105
    def return_to_baseline; end

    # source://timecop//lib/timecop/timecop.rb#114
    def safe_mode=(safe); end

    # @return [Boolean]
    #
    # source://timecop//lib/timecop/timecop.rb#118
    def safe_mode?; end

    # Allows you to run a block of code and "scale" a time throughout the execution of that block.
    # The first argument is a scaling factor, for example:
    #   Timecop.scale(2) do
    #     ... time will 'go' twice as fast here
    #   end
    # See Timecop#freeze for exact usage of the other arguments
    #
    # Returns the value of the block if one is given, or the mocked time.
    #
    # source://timecop//lib/timecop/timecop.rb#80
    def scale(*args, &block); end

    # Returns whether or not Timecop is currently scaled
    #
    # @return [Boolean]
    #
    # source://timecop//lib/timecop/timecop.rb#141
    def scaled?; end

    # source://timecop//lib/timecop/timecop.rb#126
    def thread_safe; end

    # source://timecop//lib/timecop/timecop.rb#122
    def thread_safe=(t); end

    # source://timecop//lib/timecop/timecop.rb#110
    def top_stack_item; end

    # Allows you to run a block of code and "fake" a time throughout the execution of that block.
    # See Timecop#freeze for a sample of how to use (same exact usage syntax)
    #
    # * Note: Timecop.travel will not freeze time (as opposed to Timecop.freeze).  This is a particularly
    #   good candidate for use in environment files in rails projects.
    #
    # Returns the value of the block if one is given, or the mocked time.
    #
    # source://timecop//lib/timecop/timecop.rb#68
    def travel(*args, &block); end

    # Returns whether or not Timecop is currently travelled
    #
    # @return [Boolean]
    #
    # source://timecop//lib/timecop/timecop.rb#136
    def travelled?; end

    # Reverts back to system's Time.now, Date.today and DateTime.now (if it exists) permamently when
    # no block argument is given, or temporarily reverts back to the system's time temporarily for
    # the given block.
    #
    # source://timecop//lib/timecop/timecop.rb#95
    def unfreeze(&block); end

    private

    # source://timecop//lib/timecop/timecop.rb#154
    def send_travel(mock_type, *args, &block); end
  end
end

# source://timecop//lib/timecop/timecop.rb#256
class Timecop::SafeModeException < ::StandardError
  # @return [SafeModeException] a new instance of SafeModeException
  #
  # source://timecop//lib/timecop/timecop.rb#257
  def initialize; end
end

# A data class for carrying around "time movement" objects.  Makes it easy to keep track of the time
# movements on a simple stack.
#
# source://timecop//lib/timecop/time_stack_item.rb#4
class Timecop::TimeStackItem
  # @return [TimeStackItem] a new instance of TimeStackItem
  #
  # source://timecop//lib/timecop/time_stack_item.rb#7
  def initialize(mock_type, *args); end

  # source://timecop//lib/timecop/time_stack_item.rb#69
  def current_monotonic; end

  # source://timecop//lib/timecop/time_stack_item.rb#73
  def current_monotonic_with_mock; end

  # source://timecop//lib/timecop/time_stack_item.rb#98
  def date(date_klass = T.unsafe(nil)); end

  # source://timecop//lib/timecop/time_stack_item.rb#102
  def datetime(datetime_klass = T.unsafe(nil)); end

  # source://timecop//lib/timecop/time_stack_item.rb#26
  def day; end

  # source://timecop//lib/timecop/time_stack_item.rb#30
  def hour; end

  # source://timecop//lib/timecop/time_stack_item.rb#34
  def min; end

  # source://timecop//lib/timecop/time_stack_item.rb#5
  def mock_type; end

  # source://timecop//lib/timecop/time_stack_item.rb#59
  def monotonic; end

  # source://timecop//lib/timecop/time_stack_item.rb#22
  def month; end

  # source://timecop//lib/timecop/time_stack_item.rb#94
  def scaled_time; end

  # source://timecop//lib/timecop/time_stack_item.rb#54
  def scaling_factor; end

  # source://timecop//lib/timecop/time_stack_item.rb#38
  def sec; end

  # source://timecop//lib/timecop/time_stack_item.rb#78
  def time(time_klass = T.unsafe(nil)); end

  # source://timecop//lib/timecop/time_stack_item.rb#46
  def travel_offset; end

  # source://timecop//lib/timecop/time_stack_item.rb#50
  def travel_offset_days; end

  # source://timecop//lib/timecop/time_stack_item.rb#42
  def utc_offset; end

  # source://timecop//lib/timecop/time_stack_item.rb#18
  def year; end

  private

  # source://timecop//lib/timecop/time_stack_item.rb#159
  def compute_travel_offset; end

  # source://timecop//lib/timecop/time_stack_item.rb#121
  def parse_monotonic_time(*args); end

  # source://timecop//lib/timecop/time_stack_item.rb#131
  def parse_time(*args); end

  # source://timecop//lib/timecop/time_stack_item.rb#113
  def rational_to_utc_offset(rational); end

  # source://timecop//lib/timecop/time_stack_item.rb#167
  def time_klass; end

  # source://timecop//lib/timecop/time_stack_item.rb#163
  def times_are_equal_within_epsilon(t1, t2, epsilon_in_seconds); end

  # source://timecop//lib/timecop/time_stack_item.rb#117
  def utc_offset_to_rational(utc_offset); end
end

# source://timecop//lib/timecop/version.rb#2
Timecop::VERSION = T.let(T.unsafe(nil), String)
