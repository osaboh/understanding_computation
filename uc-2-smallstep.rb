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

  def reducible?
    false	# Number は簡約できないので reduce も定義しない。
  end
end

class Add < Struct.new(:left, :right)

  def to_s
    "#{left} + #{right}"
  end

  def inspect
    "<<#{self}>>"
  end

  def reducible?
    true
  end

  def reduce(environment)
    if left.reducible?
      Add.new(left.reduce(environment), right)	# 左の項が簡約可能
    elsif right.reducible?
      Add.new(left, right.reduce(environment))	# 右の項が簡約可能
    else
      Number.new(left.value + right.value)	# 簡約できないので演算
    end
  end
end


class Multiply < Struct.new(:left, :right)

  def to_s
    "#{left} * #{right}"
  end

  def inspect
    "<<#{self}>>"
  end

  def reducible?
    true
  end

  def reduce(environment)
    if left.reducible?
      Add.new(left.reduce(environment), right)	# 左の項が簡約可能
    elsif right.reducible?
      Add.new(left, right.reduce(environment))	# 右の項が簡約可能
    else
      Number.new(left.value * right.value)	# 簡約できないので演算
    end
  end
end


# bool
class Boolean < Struct.new(:value)
  def to_s
    value.to_s
  end

  def inspect
    "<<#{self}>>"
  end

  def reducible?
    false
  end
end

# <(小なり)
class LessThan < Struct.new(:left, :right)
  def to_s
    "#{left} < #{right}"
  end

  def inspect
    "<<#{self}>>"
  end

  def reducible?
    true
  end

  def reduce(environment)
    if left.reducible?
      LessThan.new(left.reduce(environment), right)
    elsif right.reducible?
      LessThan.new(left, right.reduce(environment))
    else
      Boolean.new(left.value < right.value)
      # if left.value < right.value
      #   true
      # else
      #   false
      # end
    end
  end
end


# 変数
class Variable < Struct.new(:name)
  def to_s
    name.to_s
  end
  def inspect
    "<<#{self}>>"
  end
  def reducible?
    true
  end

  # 環境から値を取得する。
  def reduce(environment)
    environment[name]
  end
end


class DoNothing
  def to_s
    'do-nothing'
  end

  def inspect
    "<<#{self}>>"
  end

  def ==(other_statement)
    other_statement.instance_of?(DoNothing)
  end

  def reducible?
    false
  end
end

class Assign <Struct.new(:name, :expression)
  def to_s
    "#{name} = #{expression}"
  end

  def inspect
    "<<#{self}>>"
  end

  def reducible?
    true
  end

  def reduce(environment)
    if expression.reducible?
      [Assign.new(name, expression.reduce(environment)), environment]
    else
      # hash.merge(other_hash) 2 つのハッシュを統合する。
      # 既存のキーがあれば other_hash の値が使われる。
      # (実行の最後も)環境が更新される。
      [DoNothing.new, environment.merge({name => expression})]
    end
  end
end

class Machine < Struct.new(:statement, :environment)	# 文と環境が必要
#class Machine < Struct.new(:expression, :environment)	# 式と環境が必要

  def step


    # 現在は Assign のみハッシュを返すが、全てハッシュを
    # 返すように変更するのが正しい ?
    if statement.instance_of?(Assign)
      # 環境が更新される。
      self.statement, self.environment = statement.reduce(environment)
    else
      self.statement = statement.reduce(environment)
    end
  end

  def run
    while statement.reducible?
      puts "#{statement}, #{environment}"
      step
    end
    puts "#{statement}, #{environment}"
  end
end


def m1
  Machine.new(
    Add.new(Multiply.new(
             Number.new(1),
             Number.new(2)),
            Multiply.new(
              Number.new(3),
              Number.new(4))
           ),
    {} # 空の環境
  )
end

def m2
  Machine.new(
    LessThan.new(Number.new(5),
                 Add.new(
                   Number.new(2),
                   Number.new(2))),
    {}
  )

end

def m3
  Machine.new(
    Add.new(Variable.new(:x),
            Variable.new(:y)),
    {x: Number.new(3),
     y: Number.new(4)}
  )
end


# irb 上で定義した rr で /tmp/__currrent.rb を require する。
# main.run で実行する。
def main
  Machine.new(
    Assign.new(:x,
               Add.new(Variable.new(:x),
                       Number.new(1))),
    {x: Number.new(2)}
  )
end

