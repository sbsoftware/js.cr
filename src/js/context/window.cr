require "./context_object"
require "./timer_handle"
require "./undefined"
require "./window_member"

module JS
  module Context
    alias TimerDelay = Int::Primitive | Float32 | Float64
    alias TimerCallback = String | JS::Context::ContextObject

    class Window < JS::Context::ContextObject
      def initialize
        super("window")
      end

      def setTimeout : JS::Context::WindowMember
        JS::Context::WindowMember.new("setTimeout")
      end

      def setTimeout(callback : JS::Context::TimerCallback, delay : JS::Context::TimerDelay) : JS::Context::TimerHandle
        JS::Context::TimerHandle.new(to_js_ref, "setTimeout", callback, delay)
      end

      def clearTimeout : JS::Context::WindowMember
        JS::Context::WindowMember.new("clearTimeout")
      end

      def clearTimeout(handle : JS::Context::TimerHandle) : JS::Context::Undefined
        JS::Context::Undefined.new(to_js_ref, "clearTimeout", handle)
      end
    end
  end
end
