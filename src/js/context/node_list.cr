require "./callback"
require "./context_object"
require "./undefined"

module JS
  module Context
    alias NodeListForEachCallback = JS::Context::Callback

    class NodeList < JS::Context::ContextObject
      # DSL block forms (`cards.forEach { ... }`) are emitted by JS::Code macro expansion.
      # This typed wrapper path models explicit callback references used outside macro DSL expansion.
      def forEach(callback : JS::Context::NodeListForEachCallback) : JS::Context::Undefined
        JS::Context::Undefined.new(to_js_ref, "forEach", callback)
      end
    end
  end
end
