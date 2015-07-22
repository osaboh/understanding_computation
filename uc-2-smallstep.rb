#!/usr/bin/env ruby2.1
# coding: utf-8

# O'Reilly アンダースタンディング コンピューテーション、
# 2 章の操作的意味論(スモールステップ意味論)の仮想機械
# 2015/07/22 19:58:33 osaboh
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
      Add.new(left.reduce(environment), right)	# 左の項が簡約可能
    elsif right.reducible?
      Add.new(left, right.reduce(environment))	# 右の項が簡約可能
    else
      Number.new(left.value * right.value)	# 簡約できないので演算
    end
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
            Sequence.new(body, self), DoNothing.new),
     environment]
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
  ).run
end

def m2
  Machine.new(
    LessThan.new(Number.new(5),
                 Add.new(
                   Number.new(2),
                   Number.new(2))),
    {}
  ).run

end

def m3
  Machine.new(
    Add.new(Variable.new(:x),
            Variable.new(:y)),
    {x: Number.new(3),
     y: Number.new(4)}
  ).run
end

def m4
  Machine.new(
    Assign.new(:x,
               Add.new(Variable.new(:x),
                       Number.new(1))),
    {x: Number.new(2)}
  ).run
end


def m5
  Machine.new(
    If.new(Variable.new(:x),
           Assign.new(:y,
                      Number.new(1)),
           Assign.new(:y,
                      Number.new(2))),
    {x: Boolean.new(true)}
  ).run
end


def m6
  Machine.new(
    If.new(Variable.new(:x),
           Assign.new(:y, Number.new(1)),
           DoNothing.new),
    {x: Boolean.new(true)}
  ).run
end


def m7
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

def m8
  Machine.new(
    While.new(LessThan.new(Variable.new(:x),
                           Number.new(5)),
              Assign.new(:x,
                         Multiply.new(Variable.new(:x),
                                      Number.new(3)))),
    {x: Number.new(1)}
  ).run
end


# これはエラー
# y = true + 1, {:x=> <<true>>}
# qr_26934PKK.rb:44:in `reduce': undefined method `+' for true:TrueClass (NoMethodError)
# def m9
#   Machine.new(
#     Sequence.new(Assign.new(:x,
#                             Boolean.new(true)),
#                  Assign.new(:y,
#                             Add.new(Variable.new(:x),
#                                     Number.new(1)))),
#     {}
#   ).run
# end

def test_run
  p m1
  p m2
  p m3
  p m4
  p m5
  p m6
  p m7
  p m8
end

def main
  test_run
end

main


