require "./context_object"
require "./element"

module JS
  module Context
    class Location < JS::Context::ContextObject
      def href : JS::Context::DOMStringValue
        JS::Context::DOMStringValue.new("#{to_js_ref}.href")
      end

      def origin : JS::Context::DOMStringValue
        JS::Context::DOMStringValue.new("#{to_js_ref}.origin")
      end
    end
  end
end
