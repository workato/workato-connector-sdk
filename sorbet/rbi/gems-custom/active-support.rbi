# typed: strong
# frozen_string_literal: true

class Integer
  sig { params(format: T.any(Integer, Symbol)).returns(String) }
  def to_s(format = 10); end
end
