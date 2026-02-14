require "../../spec_helper"

module JS::Context::APISpec
  class StrictConsoleCode < JS::Code
    def_to_js strict: true do
      console.log("Hello", 7, true, nil)
      console.info("Info")
      console.warn("Warn")
      console.error("Error")
    end
  end

  describe "strict browser context console calls" do
    it "transpiles literal console calls in strict mode" do
      expected = <<-JS.squish
      console.log("Hello", 7, true, undefined);
      console.info("Info");
      console.warn("Warn");
      console.error("Error");
      JS

      StrictConsoleCode.to_js.should eq(expected)
    end
  end

  describe "typed console return value" do
    it "returns an Undefined context wrapper exposing to_js_ref" do
      result = JS::Context.default.console.log("Hello")

      result.should be_a(JS::Context::Undefined)
      result.to_js_ref.should eq("console.log(\"Hello\")")
    end
  end
end
