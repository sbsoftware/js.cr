require "../../spec_helper"

module JS::Browser::ConsoleSpec
  class ConsoleCode < JS::Code
    def_to_js do
      JS::Browser::Console.log("Hello", 7, true, nil)
      JS::Browser::Console.info("Info")
      JS::Browser::Console.warn("Warn")
      JS::Browser::Console.error("Error")
    end
  end

  describe "ConsoleCode.to_js" do
    it "should transpile typed console wrapper calls" do
      expected = <<-JS.squish
      console.log("Hello", 7, true, undefined);
      console.info("Info");
      console.warn("Warn");
      console.error("Error");
      JS

      ConsoleCode.to_js.should eq(expected)
    end
  end
end
