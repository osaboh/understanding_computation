#!/usr/bin/env ruby2.1
# coding: utf-8

# O'Reilly アンダースタンディング コンピューテーション、
# 2 章の操作的意味論(ビッグテップ意味論)の仮想機械
# * 2015/07/22 23:33:29
#
# .irbrc で以下を定義しておくと便利。
# def rr
#   require "this_code.rb"
# end

require "pp"

# 共通 inspect メソッド
module Com_inspect
  def inspect
    " <<#{self}>> "
  end
end

# 数値
class Number < Struct.new(:value)
  include Com_inspect
  def to_s
    value.to_s
  end

  def evaluate(environment)
    # 数値はこれ以上評価できないので自身を返す。
    self
  end
end

# bool
class Boolean < Struct.new(:value)
  include Com_inspect
  def to_s
    value.to_s
  end

  def evaluate(environment)
    # bool はこれ以上評価できないので自身を返す。
    self
  end
end

# 加算 "+"
class Add < Struct.new(:left, :right)
  include Com_inspect
  def to_s
    "#{left} + #{right}"
  end

  def evaluate(environment)
    Number.new(left.evaluate(environment).value + right.evaluate(environment).value)
  end
end

# 積算 "*"
class Multiply < Struct.new(:left, :right)
  include Com_inspect
  def to_s
    "#{left} * #{right}"
  end

  def evaluate(environment)
    Number.new(left.evaluate(environment).value * right.evaluate(environment).value)
  end
end


# 比較 "<"
class LessThan < Struct.new(:left, :right)
  include Com_inspect
  def to_s
    "#{left} < #{right}"
  end

  def evaluate(environment)
    Boolean.new(left.evaluate(environment).value < right.evaluate(environment).value)
  end
end


# 変数
class Variable < Struct.new(:name)
  include Com_inspect
  def to_s
    name.to_s
  end

  def evaluate(environment)
    environment[name]
  end
end


# なにもしない文
class DoNothing
  include Com_inspect
  def to_s
    'do-nothing'
  end

  # DoNothing は Struct を継承してないので演算子を定義する。
  def ==(other_statement)
    other_statement.instance_of?(DoNothing)
  end

  def evaluate(environment)
    environment
  end
end

## これ以降は文(statement) ##
# 代入文
class Assign <Struct.new(:name, :expression)
  include Com_inspect
  def to_s
    "#{name} = #{expression}"
  end

  def evaluate(environment)
    environment.merge({name => expression.evaluate(environment)})
  end
end


# if 文
class If <Struct.new(:condition, :consequence, :alternative)
  include Com_inspect
  def to_s
    "if (#{condition}) then { #{consequence} }  else { #{alternative} }"
  end

  def evaluate(environment)
    case condition.evaluate(environment)
    when Boolean.new(true)
      consequence.evaluate(environment)
    when Boolean.new(false)
      alternative.evaluate(environment)
    end
  end
end

# シーケンス文
class Sequence < Struct.new(:first, :second)
  include Com_inspect
  def to_s
    "#{first}; #{second}"
  end

  def evaluate(environment)
    second.evaluate(first.evaluate(environment))
  end

end

# while 文
class While < Struct.new(:condition, :body)
  include Com_inspect
  def to_s
    "while (#{condition}) { #{body} }"
  end

  def evaluate(environment)
    case condition.evaluate(environment)
    when Boolean.new(true)
      evaluate(body.evaluate(environment))
    # evaled_environment =  body.evaluate(environment)
    # self.evaluate(evaled_environment)    # self はなくても良いみたい。いつ必要なのか要調査
    when Boolean.new(false)
      environment
    end
  end
end

def test_run
  #== big ==
  p b9
  p b10
  p b11
end

def b9
  LessThan.new(
    Add.new(Variable.new(:x),
            Number.new(2)),
    Variable.new(:y)).evaluate({x: Number.new(2), y: Number.new(5)})
end

def b10
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
  statement =
    While.new(LessThan.new(Variable.new(:x),
                           Number.new(5)),
              Assign.new(:x,
                         Multiply.new(Variable.new(:x),
                                      Number.new(3))))
  statement.evaluate({x:  Number.new(1)})
end

def main
#  test_run
  p b9
  p b10
  p b11
end
main


