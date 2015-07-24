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


def main
  print("-- p --\n")
  p Number.new(1)		# <<1>>
  p Number.new(1).to_s		# "1"
  p Number.new(1).inspect	# "<<1>>"
  puts Number.new(1).inspect	# <<1>>
  print("-- pp --\n")
  pp Number.new(1)		# #<struct Number value=1>
  pp Number.new(1).to_s		# "1"
  pp Number.new(1).inspect	# "<<1>>"
  puts Number.new(1).inspect	# <<1>>
end

print "ruby version ",RUBY_VERSION,"\n"
main

