module JS
  module Browser
    alias MethodCallArgument = Nil | Bool | Int::Primitive | Float32 | Float64 | String | JS::Browser::MethodCall

    class MethodCall
      getter to_js_ref : String

      def initialize(@to_js_ref : String)
      end

      def append_call(*args : MethodCallArgument) : JS::Browser::MethodCall
        JS::Browser::MethodCall.new(
          String.build do |io|
            io << to_js_ref
            io << "("
            JS::Browser.serialize_args(io, *args)
            io << ")"
          end
        )
      end

      def _call(*args : MethodCallArgument) : JS::Browser::MethodCall
        append_call(*args)
      end

      def property(name : String) : JS::Browser::MethodCall
        JS::Browser::MethodCall.new("#{to_js_ref}.#{name}")
      end

      def invoke(name : String, *args : MethodCallArgument) : JS::Browser::MethodCall
        JS::Browser::MethodCall.new(
          String.build do |io|
            io << to_js_ref
            io << "."
            io << name
            io << "("
            JS::Browser.serialize_args(io, *args)
            io << ")"
          end
        )
      end

      # Keep chained Crystal syntax close to JS while producing typed call wrappers.
      macro method_missing(call)
        {% if call.name.stringify == "_call" %}
          JS::Browser::MethodCall.new(
            String.build do |io|
              io << @to_js_ref
              io << "("
              {% if call.args.empty? %}
                JS::Browser.serialize_args(io)
              {% else %}
                JS::Browser.serialize_args(io, {{call.args.splat}})
              {% end %}
              io << ")"
            end
          )
        {% else %}
        {% if call.block %}
          {% call.raise "JS::Browser::MethodCall wrappers don't support block arguments." %}
        {% end %}
        {% unless call.named_args.is_a?(Nop) %}
          {% call.raise "JS::Browser::MethodCall wrappers don't support named arguments." %}
        {% end %}
        {% if call.args.empty? %}
          property({{call.name.id.stringify}})
        {% else %}
          invoke({{call.name.id.stringify}}, {{call.args.splat}})
        {% end %}
        {% end %}
      end
    end

    def self.serialize_args(io : IO) : Nil
    end

    def self.serialize_args(io : IO, *args : MethodCallArgument) : Nil
      args.each_with_index do |arg, index|
        io << ", " unless index.zero?
        serialize_arg(io, arg)
      end
    end

    private def self.serialize_arg(io : IO, arg : Nil) : Nil
      io << "undefined"
    end

    private def self.serialize_arg(io : IO, arg : Bool) : Nil
      io << (arg ? "true" : "false")
    end

    private def self.serialize_arg(io : IO, arg : String) : Nil
      io << arg.dump
    end

    private def self.serialize_arg(io : IO, arg : Int::Primitive | Float32 | Float64) : Nil
      io << arg
    end

    private def self.serialize_arg(io : IO, arg : JS::Browser::MethodCall) : Nil
      io << arg.to_js_ref
    end
  end
end
