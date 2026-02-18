module JS
  module Context
    alias CallArgument = Nil | Bool | Int::Primitive | Float32 | Float64 | String | JS::Context::ContextObject

    abstract class ContextObject
      getter to_js_ref : String

      protected def initialize(@to_js_ref : String)
      end

      def initialize(preceding_call_chain : String, method_name : String, *args)
        @to_js_ref = JS::Context.build_call_chain(preceding_call_chain, method_name, *args)
      end
    end

    # Keep chain generation centralized so all browser context wrappers emit identical JS call syntax.
    def self.build_call_chain(preceding_call_chain : String, method_name : String, *args) : String
      String.build do |io|
        unless preceding_call_chain.empty?
          io << preceding_call_chain
          io << "."
        end
        io << method_name
        if !preceding_call_chain.empty? || !args.empty?
          io << "("
          serialize_args(io, *args)
          io << ")"
        end
      end
    end

    def self.serialize_args(io : IO, *args) : Nil
      args.each_with_index do |arg, index|
        io << ", " unless index.zero?
        serialize_arg(io, arg)
      end
    end

    private def self.serialize_arg(io : IO, arg : JS::Context::CallArgument) : Nil
      io << arg.to_js_ref
    end

    private def self.serialize_arg(io : IO, arg : NamedTuple) : Nil
      io << arg.to_js_ref
    end
  end
end
