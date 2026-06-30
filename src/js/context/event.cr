require "./context_object"

module JS
  module Context
    class Event < JS::Context::ContextObject
      def initialize(type : String, **options)
        super(JS::Context::Event.build_ref(type, options))
      end

      protected def self.build_ref(type : String, options) : String
        String.build do |io|
          io << "new Event("
          io << type.to_js_ref
          unless options.empty?
            io << ", "
            io << options.to_js_ref
          end
          io << ")"
        end
      end
    end
  end
end
