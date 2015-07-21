#!/usr/bin/env ruby2.1
# coding: utf-8

require "pp"

class Number < Struct.new(:value)

  def to_s
    value.to_s
  end

  def inspect
    "<<#{self}>>"
  end
end

class Add < Struct.new(:left, :right)

  def to_s
    "#{left} + #{right}"
  end

  def inspect
    "<<#{self}>>"
  end
end

class Multiply < Struct.new(:left, :right)

  def to_s
    "#{left} * #{right}"
  end

  def inspect
    "<<#{self}>>"
  end

end


def to_s_inspect_test
  p Number.new(1)		# <<1>>
  p Number.new(1).to_s		# "1"
  p Number.new(1).inspect	# "<<1>>"
  puts Number.new(1).inspect	# <<1>>

  pp Number.new(1)		# #<struct Number value=1>
  pp Number.new(1).to_s		# "1"
  pp Number.new(1).inspect	# "<<1>>"
  puts Number.new(1).inspect	# <<1>>

end


def main
  Add.new(
      Multiply.new(Number.new(1), Number.new(2)),
      Multiply.new(Number.new(3), Number.new(4))
    )
end


print("-- start --\n")
print "ruby version ",RUBY_VERSION,"\n"
# p なら inspect の結果を表示
# pp なら 式の値を表示

p main
print("\n-- end --\n")


