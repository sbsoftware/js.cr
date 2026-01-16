require "../../spec_helper"

module JS::Code::ProcSpec
  class MyCode < JS::Code
    def_to_js do
      myFunc = ->(x : Int32, y : Int32) { x + y }

      this.timer = setInterval(-> { console.log("Later!") }, 3000)

      obj = {
        get: ->(foo, bar) { foo.myGet(bar) },
      }
    end
  end

  describe "MyCode.to_js" do
    it "returns the correct JS code" do
      expected = <<-JS.squish
      var myFunc;
      var obj;

      myFunc = (x, y) => {x + y;};

      this.timer = setInterval(() => {console.log("Later!");}, 3000);

      obj = {
        get: (foo, bar) => {foo.myGet(bar);}
      };
      JS

      MyCode.to_js.should eq(expected)
    end
  end
end
