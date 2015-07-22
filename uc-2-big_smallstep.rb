#!/usr/bin/env ruby2.1
# coding: utf-8

# O'Reilly アンダースタンディング コンピューテーション、
# 2 章の操作的意味論(スモール & ビッグステップ意味論)の仮想機械
# * 2015/07/22 23:34:17
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

  def reducible?
    false	# Number は簡約できないので reduce も定義しない。
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

  def reducible?
    false
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

  def reducible?
    true
  end

  def reduce(environment)
    if left.reducible?
      Multiply.new(left.reduce(environment), right)	# 左の項が簡約可能
    elsif right.reducible?
      Multiply.new(left, right.reduce(environment))	# 右の項が簡約可能
    else
      Number.new(left.value * right.value)	# 簡約できないので演算
    end
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
    end
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
  def reducible?
    true
  end

  # 環境から値を取得する。
  def reduce(environment)
    environment[name]
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

  def reducible?
    false
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

  def reducible?
    true
  end

  def reduce(environment)
    if expression.reducible?
      [Assign.new(name, expression.reduce(environment)), environment]
    else
      # hash.merge(other_hash) 2 つのハッシュを統合する。
      # 既存のキーがあれば other_hash の値が使われる。
      [DoNothing.new, environment.merge({name => expression})]
    end
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

  def reducible?
    true
  end

  def reduce(environment)
    # reduce 可能なのは数値とbool、例外的に DoNothing。
    if condition.reducible?
      [If.new(condition.reduce(environment), consequence, alternative), environment]
    else
      case condition
      when Boolean.new(true)
        [consequence, environment]
      when Boolean.new(false)
        [alternative, environment]
      end
    end
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

  def reducible?
    true
  end

  def reduce(environment)
    case first
    when DoNothing.new
      [second, environment]
    else
      # first は簡約できる(文)と仮定する。
      reduced_first, reduced_environment = first.reduce(environment)
      [Sequence.new(reduced_first, second), reduced_environment]
    end
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

  def reducible?
    true
  end

  def reduce(environment)
    [If.new(condition,
            Sequence.new(body, self),
            DoNothing.new),
     environment]
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

# 簡約器
class Machine < Struct.new(:statement, :environment)

  def reduced_with_env?(term)
    term.instance_of?(Assign)	|| term.instance_of?(If) || \
    term.instance_of?(Sequence) || term.instance_of?(While)
  end

  def step
    if reduced_with_env?(statement)
      # statement の場合は環境を更新する。
      self.statement, self.environment = statement.reduce(environment)
    else
      # その他は簡約のみ行う。
      self.statement = statement.reduce(environment)
    end
  end

  def run
    # small step 意味論の「繰り返し」はここで行われる。
    puts "#{statement}, #{environment}"
    while statement.reducible?
      step
      puts "#{statement}, #{environment}"	# 1step 毎の簡約結果と環境が状態として得られる。
    end
  end
end


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
end


def main
  test_run
end
main


