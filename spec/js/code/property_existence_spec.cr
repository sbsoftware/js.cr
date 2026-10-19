require "../../spec_helper"

module JS::Code::PropertyExistenceSpec
  class PropertyExistenceCode < JS::Code
    def_to_js do
      property = "readyState"

      if "serviceWorker".in?(navigator)
        console.log("supported")
      end

      if property.in?(navigator) && !"disabled".in?(navigator) || "fallback".in?(navigator)
        console.log("available")
      end
    end
  end

  class StrictPropertyExistenceCode < JS::Code
    def_to_js strict: true do
      if "serviceWorker".in?(navigator)
        console.log("supported")
      end
    end
  end

  describe "JavaScript property-existence expressions" do
    it "renders literal and variable properties in nested conditions with stable precedence" do
      expected = <<-JS.squish
      var property;
      property = "readyState";
      if (("serviceWorker" in navigator)) {
        console.log("supported");
      }
      if (((property in navigator) && !("disabled" in navigator)) || ("fallback" in navigator)) {
        console.log("available");
      }
      JS

      PropertyExistenceCode.to_js.should eq(expected)
    end

    it "resolves typed context objects in strict mode" do
      StrictPropertyExistenceCode.to_js.should eq(%[if (("serviceWorker" in navigator)) {console.log("supported");}])
    end

    it "rejects property checks without a receiver" do
      source = <<-CR
      require "./src/js"

      class MissingReceiverCode < JS::Code
        def_to_js do
          in?(navigator)
        end
      end

      puts MissingReceiverCode.to_js
      CR

      exit_code, _stdout, stderr = crystal_eval(source)
      exit_code.should_not eq(0)
      stderr.should contain("JavaScript property-existence checks require a receiver. Use `property.in?(object)`.")
    end

    it "rejects property checks with the wrong arity" do
      [%("serviceWorker".in?()), %("serviceWorker".in?(navigator, window))].each do |property_check|
        source = <<-CR
        require "./src/js"

        class WrongArityCode < JS::Code
          def_to_js do
            #{property_check}
          end
        end

        puts WrongArityCode.to_js
        CR

        exit_code, _stdout, stderr = crystal_eval(source)
        exit_code.should_not eq(0)
        stderr.should contain("JavaScript property-existence checks accept exactly one argument. Use `property.in?(object)`.")
      end
    end
  end
end
