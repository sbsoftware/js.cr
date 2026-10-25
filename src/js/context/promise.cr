require "./context_object"

module JS
  module Context
    class Promise(T) < JS::Context::ContextObject
      def initialize(to_js_ref : String)
        super(to_js_ref)
      end

      def initialize(preceding_call_chain : String, method_name : String, *args)
        super(preceding_call_chain, method_name, *args)
      end
    end
  end
end
