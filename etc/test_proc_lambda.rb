#!/usr/bin/env ruby2.1
# coding: utf-8

# proc のテスト

def proc_test
  p proc_obj = -> (arg) {arg + 1}
  p proc_obj.call(1)
  # => 2

  # 実は 「-> ARG {}」は lambda の構文糖。
  p lambda_obj = lambda {|arg| arg + 1}
  p lambda_obj.call(1)
  # => 2

  # 引数は複数も可能。括弧は省略可能。
  p proc_obj = -> arg1, arg2 {arg1 + arg2}
  p proc_obj.call(1,1)
  # => 2

  # 引数は必須ではない
  p proc_obj = -> {1 + 1}
  p proc_obj.call()
  # => 2
end

proc_test

