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
      c = j % 3

      if x > 0 && x >= y || x < 0 && x <= y
        console.log("yes")
      end
      z += 1 if a == b
      x -= 1 if x >= j
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
      var c;

      i = 10000;
      j = i * 20;
      y = j + 10;
      x = y - 2;
      z = x / 2;
      a = i * j * z + 4;
      b = 4 * 4;
      c = j % 3;
      if ((x > 0 && x >= y) || (x < 0 && x <= y)) {
        console.log("yes");
      }
      if (a == b) {
        z = z + 1;
      }
      if (x >= j) {
        x = x - 1;
      }
      JS

      MyCode.to_js.should eq(expected)
    end
  end

  class ChainedOperatorReceiverCode < JS::Code
    def_to_js do
      (a + b).toString._call
    end
  end

  describe "ChainedOperatorReceiverCode.to_js" do
    it "preserves parentheses around operator expressions used as call receivers" do
      ChainedOperatorReceiverCode.to_js.should eq("(a + b).toString();")
    end
  end

  class ComplexChainedOperatorReceiverCode < JS::Code
    def_to_js do
      ((a + b) * (c - d)).toString._call
      (left.toString._call + right.trim._call).valueOf._call
      ((before.normalize._call + after.normalize._call) / total).toFixed(2)
    end
  end

  describe "ComplexChainedOperatorReceiverCode.to_js" do
    it "preserves grouping for nested operator receivers and chained-call operands" do
      expected = <<-JS.squish
      ((a + b) * (c - d)).toString();
      (left.toString() + right.trim()).valueOf();
      ((before.normalize() + after.normalize()) / total).toFixed(2);
      JS

      ComplexChainedOperatorReceiverCode.to_js.should eq(expected)
    end
  end
end
