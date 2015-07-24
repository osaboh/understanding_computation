#!/usr/bin/env ruby2.1
# coding: utf-8

require './uc-2-semantics.rb'

def s1
  Machine.new(
    Add.new(Multiply.new(
             Number.new(1),
             Number.new(2)),
            Multiply.new(
              Number.new(3),
              Number.new(4))
           ),
    {} # 空の環境
  ).run
end

def s2
  Machine.new(
    LessThan.new(Number.new(5),
                 Add.new(
                   Number.new(2),
                   Number.new(2))),
    {}
  ).run

end

def s3
  Machine.new(
    Add.new(Variable.new(:x),
            Variable.new(:y)),
    {x: Number.new(3),
     y: Number.new(4)}
  ).run
end

def s4
  Machine.new(
    Assign.new(:x,
               Add.new(Variable.new(:x),
                       Number.new(1))),
    {x: Number.new(2)}
  ).run
end


def s5
  Machine.new(
    If.new(Variable.new(:x),
           Assign.new(:y,
                      Number.new(1)),
           Assign.new(:y,
                      Number.new(2))),
    {x: Boolean.new(true)}
  ).run
end


def s6
  Machine.new(
    If.new(Variable.new(:x),
           Assign.new(:y, Number.new(1)),
           DoNothing.new),
    {x: Boolean.new(true)}
  ).run
end


def s7
  Machine.new(
    Sequence.new(Assign.new(:x,
                            Add.new(Number.new(1),
                                    Number.new(1))),
                 Assign.new(:y,
                            Add.new(Variable.new(:x),
                                    Number.new(3)))),
    {}
  ).run
end

def s8
  Machine.new(
    While.new(LessThan.new(Variable.new(:x),
                           Number.new(5)),
              Assign.new(:x,
                         Multiply.new(Variable.new(:x),
                                      Number.new(3)))),
    {x: Number.new(1)}
  ).run
end




def b9
  # x=2,y=5
  # x + 2 < y
  statement =
    LessThan.new(Add.new(Variable.new(:x),
                         Number.new(2)),
                 Variable.new(:y))

  # 最初の LessThen から順に evaluate される。
  # 数値、bool, DoNothing が得られたら戻る。
  statement.evaluate({x: Number.new(2),
                      y: Number.new(5)})
end

def b10
  # x = 1 + 1, y = x + 3
  statement =
    Sequence.new(Assign.new(:x,
                            Add.new(Number.new(1),
                                    Number.new(1))),
                 Assign.new(:y,
                            Add.new(Variable.new(:x),
                                    Number.new(3))))
  statement.evaluate({})
end

def b11
  # x = 1
  # while (x < 5)
  #   x = x * 3
  statement =
    While.new(LessThan.new(Variable.new(:x),
                           Number.new(5)),
              Assign.new(:x,
                         Multiply.new(Variable.new(:x),
                                      Number.new(3))))
  statement.evaluate({x:  Number.new(1)})
end


def d1
  # to_ruby の値を eval すると Proc (lambda?) が返る。
  p proc = eval(Number.new(5).to_ruby)
  p proc.call({})
  p proc = eval(Boolean.new(false).to_ruby)
  p proc.call({})
end

def d2
  p expression = Variable.new(:x)
  p expression.to_ruby
  p proc = eval(expression.to_ruby)
  p proc.call({x: 7})	# call の引数が lambda の引数になる。
end

def d3
  environment = {x: 3}
  # x = 3
  # x + 1
  p proc = eval(Add.new(Variable.new(:x),
                        Number.new(1)).to_ruby)
  p proc.call(environment)

  # x + 1 < 3
  p proc = eval(LessThan.new(Add.new(Variable.new(:x),
                                     Number.new(1)),
                             Number.new(3)).to_ruby)
  p proc.call(environment)
end

def d4
  p statement = Assign.new(:y, Add.new(Variable.new(:x),
                                     Number.new(1)))
  p statement.to_ruby
  p eval(statement.to_ruby)
  p eval(statement.to_ruby).call({x: 3})
end

def d5
  p statement = While.new(LessThan.new(Variable.new(:x),
                                     Number.new(5)),
                        Assign.new(:x,
                                   Multiply.new(Variable.new(:x),
                                                Number.new(3))))
  p statement.to_ruby
  p proc = eval(statement.to_ruby)
  p proc.call({x: 1})
end

def test_run
  #== small ==
  p s1
  p s2
  p s3
  p s4
  p s5
  p s6
  p s7
  p s8
  #== big ==
  p b9
  p b10
  p b11

  # == denotional ==
  d1
  d2
  d3
  d4
  d5
end

test_run

