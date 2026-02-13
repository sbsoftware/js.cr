require "../../spec_helper"

module JS::Browser::APISpec
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

  describe "method call wrapper chains" do
    it "builds chained JS references transitively" do
      ref = JS::Browser.default_context.console
        .log("Hello")
        .next_step("done")
        ._call
        .to_js_ref

      ref.should eq("console.log(\"Hello\").next_step(\"done\")()")
    end
  end
end
