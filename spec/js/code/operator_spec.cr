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

      if x > 0 && x >= y || x < 0 && x <= y
        console.log("yes")
      end
      c = a if a == b
      d = x if x >= j
    end
  end

  describe "MyCode.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      var i;
      var j;
      var y;
      var x;
      var z;
      var a;
      var b;

      i = 10000;
      j = i * 20;
      y = j + 10;
      x = y - 2;
      z = x / 2;
      a = i * j * z + 4;
      b = 4 * 4;
      if ((x > 0 && x >= y) || (x < 0 && x <= y)) {
        console.log("yes");
      }
      if (a == b) {
        var c;
        c = a;
      }
      if (x >= j) {
        var d;
        d = x;
      }
      JS

      MyCode.to_js.should eq(expected)
    end
  end
end
