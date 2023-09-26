require "./code"
require "./method"

module JS
  abstract class Class
    @@js_extends : String?
    @@static_properties = [] of String
    @@js_methods = [] of JS::Method.class

    def self.class_name
      name.split("::")[-1]
    end

    macro js_extends(name)
      @@js_extends = {{name.id.stringify}}
    end

    macro static(assignment)
      @@static_properties << {{assignment.stringify}}
    end

    macro js_method(name, &blk)
      class {{name.id.stringify.camelcase.id}} < JS::Method
        def_to_js {{blk}}
      end

      @@js_methods << {{name.id.stringify.camelcase.id}}

      def self.{{name.id}}
        {{name.id.stringify.camelcase.id}}
      end
    end

    def self.to_js(io : IO)
      io << "class "
      io << class_name
      if @@js_extends
        io << " extends "
        io << @@js_extends
      end
      io << " {"
      @@static_properties.each do |prop|
        io << "static "
        io << prop
        io << ";"
      end
      @@js_methods.each do |js_method|
        js_method.to_js(io)
      end
      io << "}"
    end

    def self.to_js
      String.build do |str|
        to_js(str)
      end
    end
  end
end
