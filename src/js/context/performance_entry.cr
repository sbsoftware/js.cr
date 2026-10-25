require "./context_object"

module JS
  module Context
    class PerformanceString < JS::Context::ContextObject
    end

    class PerformanceNumber < JS::Context::ContextObject
    end

    class PerformanceEntry < JS::Context::ContextObject
      def name : JS::Context::PerformanceString
        JS::Context::PerformanceString.new("#{to_js_ref}.name")
      end

      def entryType : JS::Context::PerformanceString
        JS::Context::PerformanceString.new("#{to_js_ref}.entryType")
      end

      def startTime : JS::Context::PerformanceNumber
        JS::Context::PerformanceNumber.new("#{to_js_ref}.startTime")
      end

      def duration : JS::Context::PerformanceNumber
        JS::Context::PerformanceNumber.new("#{to_js_ref}.duration")
      end
    end
  end
end
