require "../../spec_helper"

module JS::Code::OperatorSpec
  class MyCode < JS::Code
    MY_CRYSTAL_VALUE = 4

    def_to_js do
      i = 10000
      j = i * 20
      y = j + 10
      x = y - 2
      z = x / 2
      a = i * j * z + MY_CRYSTAL_VALUE.to_js_ref
      b = MY_CRYSTAL_VALUE.to_js_ref * sizeof(Int32).to_js_ref
    end
  end

  describe "MyCode.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      var i = 10000;
      var j = i * 20;
      var y = j + 10;
      var x = y - 2;
      var z = x / 2;
      var a = ((i * j) * z) + 4;
      var b = 4 * 4;
      JS

      MyCode.to_js.should eq(expected)
    end
  end
end
