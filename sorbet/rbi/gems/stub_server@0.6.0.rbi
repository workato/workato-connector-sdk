# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `stub_server` gem.
# Please instead update this file by running `bin/tapioca gem stub_server`.

# source://stub_server//lib/stub_server.rb#5
class StubServer
  # @return [StubServer] a new instance of StubServer
  #
  # source://stub_server//lib/stub_server.rb#14
  def initialize(port, replies, ssl: T.unsafe(nil), json: T.unsafe(nil), webrick: T.unsafe(nil)); end

  # source://stub_server//lib/stub_server.rb#25
  def boot; end

  # source://stub_server//lib/stub_server.rb#58
  def call(env); end

  # source://stub_server//lib/stub_server.rb#69
  def shutdown; end

  # source://stub_server//lib/stub_server.rb#54
  def wait; end

  class << self
    # source://stub_server//lib/stub_server.rb#6
    def open(port, replies, **options); end
  end
end
