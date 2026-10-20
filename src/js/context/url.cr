require "./context_object"
require "./element"

module JS
  module Context
    alias URLArgument = String | JS::Context::DOMStringValue

    class URL < JS::Context::ContextObject
      def self.to_js_ref : String
        "URL"
      end

      def initialize(value : JS::Context::URLArgument)
        super(JS::Context.build_call_chain("", "new URL", value))
      end

      def initialize(value : JS::Context::URLArgument, base : JS::Context::URLArgument)
        super(JS::Context.build_call_chain("", "new URL", value, base))
      end

      def href : JS::Context::DOMStringValue
        JS::Context::DOMStringValue.new("#{to_js_ref}.href")
      end

      def origin : JS::Context::DOMStringValue
        JS::Context::DOMStringValue.new("#{to_js_ref}.origin")
      end

      def pathname : JS::Context::DOMStringValue
        JS::Context::DOMStringValue.new("#{to_js_ref}.pathname")
      end
    end
  end
end
