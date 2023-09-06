abstract class JsModule
  @@functions = [] of JsFunction.class

  macro function(name, &blk)
    class {{name.id.stringify.camelcase.id}} < JsFunction
      def_to_js {{blk}}
    end

    @@functions << {{name.id.stringify.camelcase.id}}

    def self.{{name.id}}
      {{name.id.stringify.camelcase.id}}
    end
  end

  macro def_to_js(&blk)
    def self.to_js(io : IO)
      @@functions.each do |func|
        func.to_js(io)
      end
      JsCode._eval_js_block(io) {{blk}}
    end

    def self.to_js
      String.build do |str|
        to_js(str)
      end
    end
  end
end
