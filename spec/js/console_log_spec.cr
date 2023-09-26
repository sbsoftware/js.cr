require "../spec_helper"

module JS::ConsoleLogSpec
  class ConsoleCode < JS::Code
    def_to_js do
      console.log("Hello World!")
      window.console.log("Next try")
    end
  end

  describe "ConsoleCode.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      console.log("Hello World!");
      window.console.log("Next try");
      JS

      ConsoleCode.to_js.should eq(expected)
    end
  end
end
