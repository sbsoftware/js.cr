require "../../spec_helper"

module JS::Code::LiteralJSSpec
  class MyCode < JS::Code
    def_to_js do
      _literal_js(<<-JS.squish)
      for (var x = 0;x > 10;x++) {
        console.log(x);
      }
      JS

      console.log(_literal_js("new Uint8Array(10)"))
    end
  end

  describe "MyCode.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      for (var x = 0;x > 10;x++) {
        console.log(x);
      }
      console.log(new Uint8Array(10));
      JS

      MyCode.to_js.should eq(expected)
    end
  end
end
