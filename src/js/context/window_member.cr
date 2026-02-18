require "./context_object"

module JS
  module Context
    class WindowMember < JS::Context::ContextObject
      def initialize(name : String)
        super("window.#{name}")
      end
    end
  end
end
