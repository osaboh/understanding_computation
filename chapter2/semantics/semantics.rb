#!/usr/bin/env ruby2.1
# coding: utf-8

# O'Reilly アンダースタンディング コンピューテーション、
# 2 章操作的意味論、表示的意味論
# * 2015/07/22 23:34:17

# 共通 inspect メソッド
module Com_inspect
  def inspect
    " << #{self} >> "
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

  def reducible?
    false
  end

  def evaluate(environment)
    # bool はこれ以上評価できないので自身を返す。
    self
  end

  def to_ruby
    value_of = "#{value.inspect}"
    "-> e { #{value_of} }"
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

  def to_ruby
    left_of  = "#{left.to_ruby}"
    right_of = "#{right.to_ruby}"
    "-> e { #{left_of}.call(e) + #{right_of}.call(e) }"
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

  def to_ruby
    left_of  = "#{left.to_ruby}"
    right_of = "#{right.to_ruby}"
    "-> e { #{left_of}.call(e) * #{right_of}.call(e) }"
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

  def to_ruby
    left_of  = "#{left.to_ruby}"
    right_of = "#{right.to_ruby}"
    "-> e { #{left_of}.call(e) < #{right_of}.call(e) }"
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

  def to_ruby
    # 環境内の name を得る。
    name_of = "e[#{name.inspect}]"
    "-> e { #{name_of} }"
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

  def to_ruby
    "-> e {e}"
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

  def to_ruby
    name_of = "#{name.inspect}"
    expression_of = "#{expression.to_ruby}"
    "-> e { e.merge({ #{name_of} => #{expression_of}.call(e) }) }"
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

  def to_ruby
    first_of = "#{first.to_ruby}"
    second_of = "#{second.to_ruby}"
    "-> e { second_of.call( fisrt_of.call(e)) }"
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

# == EOF ==
