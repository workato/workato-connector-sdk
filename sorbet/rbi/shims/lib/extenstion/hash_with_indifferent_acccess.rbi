# typed: strict
# frozen_string_literal: true

module ActiveSupport
  class HashWithIndifferentAccess
    class << self
      sig { params(value: T.nilable(T::Hash[T.untyped, T.untyped])).returns(HashWithIndifferentAccess) }
      def wrap(value); end
    end
  end
end
