#!/usr/bin/env ruby2.1
# coding: utf-8

# O'Reilly アンダースタンディング コンピューテーション、
# 2 章の 「SIMPLE」 を表示敵意味論によって ruby に変換する。
# * 2015/07/24 01:23:24

require "pp"

# 共通 inspect メソッド
module Com_inspect
  def inspect
    "<< #{self} >>"
  end
end

# 数値
class Number < Struct.new(:value)
  include Com_inspect
  def to_s
    value.to_s
  end

  def to_ruby
    value_of = "#{value.inspect}"
    "-> e { #{value_of} }"
  end
end

# bool
class Boolean < Struct.new(:value)
  include Com_inspect
  def to_s
    value.to_s
  end

  def to_ruby
    value_of = "#{value.inspect}"
    "-> e { #{value_of} }"
  end
end

class Variable < Struct.new(:name)
  include Com_inspect
  def to_s
    name.to_s
  end

  def to_ruby
    # 環境内の name を得る。
    name_of = "e[#{name.inspect}]"
    "-> e { #{name_of} }"
  end
end

class Add < Struct.new(:left, :right)
  include Com_inspect
  def to_s
    "#{left} + #{right}"
  end

  def to_ruby
    left_of  = "#{left.to_ruby}"
    right_of = "#{right.to_ruby}"
    "-> e { #{left_of}.call(e) + #{right_of}.call(e) }"
  end
end

class Multiply < Struct.new(:left, :right)
  include Com_inspect
  def to_s
    "#{left} * #{right}"
  end

  def to_ruby
    left_of  = "#{left.to_ruby}"
    right_of = "#{right.to_ruby}"
    "-> e { #{left_of}.call(e) * #{right_of}.call(e) }"
  end
end

class LessThan < Struct.new(:left, :right)
  include Com_inspect
  def to_s
    "#{left} < #{right}"
  end

  def to_ruby
    left_of  = "#{left.to_ruby}"
    right_of = "#{right.to_ruby}"
    "-> e { #{left_of}.call(e) < #{right_of}.call(e) }"
  end
end


class Assign <Struct.new(:name, :expression)
  include Com_inspect
  def to_s
    "#{name} = #{expression}"
  end

  def to_ruby
    name_of = "#{name.inspect}"
    expression_of = "#{expression.to_ruby}"
    "-> e { e.merge({ #{name_of} => #{expression_of}.call(e) }) }"
  end
end

class DoNothing
  include Com_inspect
  def to_s
    'do-nothing'
  end

  def to_ruby
    "-> e {e}"
  end
end

class If <Struct.new(:condition, :consequence, :alternative)
  include Com_inspect
  def to_s
    "if (#{condition}) then { #{consequence} }  else { #{alternative} }"
  end

  def to_ruby
    condition_of   = "#{condition.to_ruby}"
    consequence_of = "#{consequence.to_ruby}"
    alternative_of = "#{alternative.to_ruby}"

    "-> e {" \
    "  if #{condition_of}.call(e) then" \
    "    #{consequence_of}.call(e)" \
    "  else" \
    "    #{alternative_of}.call(e)" \
    "  end" \
    "}"
  end
end

class Sequence < Struct.new(:first, :second)
  include Com_inspect
  def to_s
    "#{first}; #{second}"
  end

  def to_ruby
    first_of = "#{first.to_ruby}"
    second_of = "#{second.to_ruby}"
    "-> e { second_of.call( fisrt_of.call(e)) }"
  end
end


class While < Struct.new(:condition, :body)
  include Com_inspect
  def to_s
        "while (#{condition}) { #{body} }"
  end

  def to_ruby
    condition_of = "#{condition.to_ruby}"
    body_of = "#{body.to_ruby}"
    "-> e {" \
    "  while #{condition_of}.call(e) do" \
    "    e = #{body_of}.call(e)" \
    "  end;" \
    "e }"	# 最後に e を返す。
  end
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
  d1
  d2
  d3
  d4
  d5
end

test_run

