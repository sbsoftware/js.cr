module JS
  module Browser
    alias MethodCallArgument = Nil | Bool | Int::Primitive | Float32 | Float64 | String | JS::Browser::MethodCall

    class MethodCall
      getter to_js_ref : String

      def initialize(@to_js_ref : String)
      end

      def _call(*args : MethodCallArgument) : JS::Browser::MethodCall
        JS::Browser::MethodCall.new(
          String.build do |io|
            io << to_js_ref
            io << "("
            JS::Browser.serialize_args(io, *args)
            io << ")"
          end
        )
      end

      def _call : JS::Browser::MethodCall
        JS::Browser::MethodCall.new("#{to_js_ref}()")
      end

      def property(name : String) : JS::Browser::MethodCall
        JS::Browser::MethodCall.new("#{to_js_ref}.#{name}")
      end

      def call(name : String, *args : MethodCallArgument) : JS::Browser::MethodCall
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

    # Keep one generic fallback for JS-context wrapper values that expose #to_js_ref.
    private def self.serialize_arg(io : IO, arg) : Nil
      io << arg.to_js_ref
    end
  end
end
