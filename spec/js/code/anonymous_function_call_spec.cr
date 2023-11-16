require "../../spec_helper"

module JS::Code::AnonymousFunctionCallSpec
  class MyJS < JS::Code
    def_to_js do
      arr = Uint8Array.from("test") do |c|
        return c.charCodeAt(0)
      end
    end
  end

  describe "MyJS.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      var arr = Uint8Array.from("test", function(c) {
        return c.charCodeAt(0);
      });
      JS

      MyJS.to_js.should eq(expected)
    end
  end
end
