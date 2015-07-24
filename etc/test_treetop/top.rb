#!/usr/bin/env ruby2.1
# coding: utf-8

require 'treetop'
Treetop.load('./calc.tt')

p CalcParser.new.parse("1+2")
p result = CalcParser.new.parse("10+2").value
p result = CalcParser.new.parse("100-66").value

