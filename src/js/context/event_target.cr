require "./context_object"
require "./event"
require "./undefined"

module JS
  module Context
    class EventDispatchResult < JS::Context::ContextObject
    end

    class EventTarget < JS::Context::ContextObject
      def initialize(to_js_ref : String)
        super(to_js_ref)
      end

      def initialize(preceding_call_chain : String, method_name : String, *args)
        super(preceding_call_chain, method_name, *args)
      end

      def addEventListener(type, listener, options = nil) : JS::Context::Undefined
        event_listener_call("addEventListener", type, listener, options)
      end

      def removeEventListener(type, listener, options = nil) : JS::Context::Undefined
        event_listener_call("removeEventListener", type, listener, options)
      end

      def dispatchEvent(event) : JS::Context::EventDispatchResult
        JS::Context::EventDispatchResult.new(to_js_ref, "dispatchEvent", event)
      end

      private def event_listener_call(name : String, type, listener, options) : JS::Context::Undefined
        if options.nil?
          JS::Context::Undefined.new(to_js_ref, name, type, listener)
        else
          JS::Context::Undefined.new(to_js_ref, name, type, listener, options)
        end
      end
    end
  end
end
