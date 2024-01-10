# frozen_string_literal: true

require "timecop"

class Minitest::Spec
  def within_same_period(&block)
    Timecop.freeze(&block)
  end
end
