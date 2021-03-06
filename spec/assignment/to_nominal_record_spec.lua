local tl = require("tl")
local util = require("spec.util")

describe("assignment to nominal record", function()
   it("accepts empty table", function()
      local tokens = tl.lex([[
         local Node = record
            b: boolean
         end
         local x: Node = {}
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)

   it("accepts complete table", function()
      local tokens = tl.lex([[
         local R = record
            foo: string
         end
         local AR = record
            {Node}
            bar: string
         end
         local Node = record
            b: boolean
            n: number
            m: {number: string}
            a: {boolean}
            r: R
            ar: AR
         end
         local x: Node = {
            b = true,
            n = 1,
            m = {},
            a = {},
            r = {},
            ar = {},
         }
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)

   it("accepts incomplete table", function()
      local tokens = tl.lex([[
         local Node = record
            b: boolean
            n: number
         end
         local x: Node = {
            b = true,
         }
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.same({}, errors)
   end)

   it("fails if table has extra fields", function()
      local tokens = tl.lex([[
         local Node = record
            b: boolean
            n: number
         end
         local x: Node = {
            b = true,
            bla = 12,
         }
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.is_not.same({}, errors)
      assert.match("in local declaration: x: unknown field bla", errors[1].msg, 1, true)
   end)

   it("fails if mismatch", function()
      local tokens = tl.lex([[
         local Node = record
            b: boolean
         end
         local x: Node = 123
      ]])
      local _, ast = tl.parse_program(tokens)
      local errors = tl.type_check(ast)
      assert.match("in local declaration: x: got number, expected Node", errors[1].msg, 1, true)
   end)

   it("type system is nominal: fails if different records with compatible structure", util.check_type_error([[
      local Node1 = record
         b: boolean
      end

      local Node2 = record
         b: boolean
      end

      local n1: Node1 = { b = true }
      local n2: Node2 = { b = true }
      n1 = n2
   ]], {
      { msg = "in assignment: Node2 is not a Node1" },
   }))

   it("identical generic instances resolve to the same type", util.check [[
      local R = record<T>
         x: T
      end

      local function foo(): R<string>
         return { x = "hello" }
      end

      local function bar(): R<string>
         return { x = "world" }
      end

      local v = foo()
      v = bar()
   ]])
end)
