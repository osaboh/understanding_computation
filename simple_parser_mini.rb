#!/usr/bin/env ruby2.1
require 'treetop'
require './uc-2-semantics.rb'

Treetop.load('./simple_grammar_mini.tt')

p code = 'while ( x < 5 ) { x = x * 3 }'
p code = code.gsub(" ", "")	# without space
p parse_tree = SimpleParser.new.parse(code)

p statement = parse_tree.to_ast
p statement.to_ruby
p statement.evaluate({x: Number.new(1)})


