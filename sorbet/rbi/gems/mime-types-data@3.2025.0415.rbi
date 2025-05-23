# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `mime-types-data` gem.
# Please instead update this file by running `bin/tapioca gem mime-types-data`.

# source://mime-types-data//lib/mime/types/data.rb#3
module MIME; end

# source://mime-types-data//lib/mime/types/data.rb#4
class MIME::Types
  extend ::Enumerable

  # source://mime-types/3.6.2/lib/mime/types.rb#72
  def initialize; end

  # source://mime-types/3.6.2/lib/mime/types.rb#122
  def [](type_id, complete: T.unsafe(nil), registered: T.unsafe(nil)); end

  # source://mime-types/3.6.2/lib/mime/types.rb#164
  def add(*types); end

  # source://mime-types/3.6.2/lib/mime/types.rb#185
  def add_type(type, quiet = T.unsafe(nil)); end

  # source://mime-types/3.6.2/lib/mime/types.rb#78
  def count; end

  # source://mime-types/3.6.2/lib/mime/types.rb#87
  def each; end

  # source://mime-types/3.6.2/lib/mime/types.rb#82
  def inspect; end

  # source://mime-types/3.6.2/lib/mime/types.rb#150
  def of(filename); end

  # source://mime-types/3.6.2/lib/mime/types.rb#150
  def type_for(filename); end

  private

  # source://mime-types/3.6.2/lib/mime/types.rb#198
  def add_type_variant!(mime_type); end

  # source://mime-types/3.6.2/lib/mime/types.rb#208
  def index_extensions!(mime_type); end

  # source://mime-types/3.6.2/lib/mime/types.rb#218
  def match(pattern); end

  # source://mime-types/3.6.2/lib/mime/types.rb#212
  def prune_matches(matches, complete, registered); end

  # source://mime-types/3.6.2/lib/mime/types.rb#202
  def reindex_extensions!(mime_type); end

  class << self
    # source://mime-types/3.6.2/lib/mime/types/registry.rb#16
    def [](type_id, complete: T.unsafe(nil), registered: T.unsafe(nil)); end

    # source://mime-types/3.6.2/lib/mime/types/registry.rb#41
    def add(*types); end

    # source://mime-types/3.6.2/lib/mime/types/registry.rb#21
    def count; end

    # source://mime-types/3.6.2/lib/mime/types/deprecations.rb#7
    def deprecated(options = T.unsafe(nil), &block); end

    # source://mime-types/3.6.2/lib/mime/types/registry.rb#26
    def each; end

    # source://mime-types/3.6.2/lib/mime/types/logger.rb#13
    def logger; end

    # source://mime-types/3.6.2/lib/mime/types/logger.rb#16
    def logger=(logger); end

    # source://mime-types/3.6.2/lib/mime/types/registry.rb#9
    def new(*_arg0); end

    # source://mime-types/3.6.2/lib/mime/types/registry.rb#35
    def of(filename); end

    # source://mime-types/3.6.2/lib/mime/types/registry.rb#35
    def type_for(filename); end

    private

    # source://mime-types/3.6.2/lib/mime/types/deprecations.rb#50
    def __deprecation_logged?(message, once); end

    # source://mime-types/3.6.2/lib/mime/types/registry.rb#77
    def __instances__; end

    # source://mime-types/3.6.2/lib/mime/types/registry.rb#57
    def __types__; end

    # source://mime-types/3.6.2/lib/mime/types/registry.rb#47
    def lazy_load?; end

    # source://mime-types/3.6.2/lib/mime/types/registry.rb#67
    def load_default_mime_types(mode = T.unsafe(nil)); end

    # source://mime-types/3.6.2/lib/mime/types/registry.rb#62
    def load_mode; end

    # source://mime-types/3.6.2/lib/mime/types/registry.rb#81
    def reindex_extensions(type); end
  end
end

# source://mime-types-data//lib/mime/types/data.rb#5
module MIME::Types::Data; end

# The path that will be used for loading the MIME::Types data. The
# default location is __FILE__/../../../../data, which is where the data
# lives in the gem installation of the mime-types-data library.
#
# The MIME::Types::Loader will load all JSON or columnar files contained
# in this path.
#
# System maintainer note: this is the constant to change when packaging
# mime-types for your system. It is recommended that the path be
# something like /usr/share/ruby/mime-types/.
#
# source://mime-types-data//lib/mime/types/data.rb#18
MIME::Types::Data::PATH = T.let(T.unsafe(nil), String)

# source://mime-types-data//lib/mime/types/data.rb#6
MIME::Types::Data::VERSION = T.let(T.unsafe(nil), String)
