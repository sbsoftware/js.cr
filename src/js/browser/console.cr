module JS
  module Browser
    alias ConsoleArgument = Nil | Bool | Int::Primitive | Float32 | Float64 | String

    # This maps the Crystal wrapper type to the global `console` object in JS.
    abstract class Console
      def self.to_js_ref
        "console"
      end

      def self.log(*args : ConsoleArgument) : Nil
      end

      def self.info(*args : ConsoleArgument) : Nil
      end

      def self.warn(*args : ConsoleArgument) : Nil
      end

      def self.error(*args : ConsoleArgument) : Nil
      end
    end
  end
end
