require "./performance_entry"

module JS
  module Context
    class PerformanceResourceTiming < JS::Context::PerformanceEntry
      def initiatorType : JS::Context::PerformanceString
        JS::Context::PerformanceString.new("#{to_js_ref}.initiatorType")
      end
    end
  end
end
