require "../../spec_helper"

module JS::Code::IfElseSpec
  class MyCode < JS::Code
    def_to_js do
      console.log(a) if a == 2

      if c > 3
        foo.bar = 7
      else
        foo.bar = 5
      end

      if something == "test"
        console.log("Yeah!")
      else
        console.log("Booo!")
      end
    end
  end

  describe "MyCode.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      if (a == 2) {
        console.log(a);
      }

      if (c > 3) {
        foo.bar = 7;
      } else {
        foo.bar = 5;
      }

      if (something == "test") {
        console.log("Yeah!");
      } else {
        console.log("Booo!");
      }
      JS

      MyCode.to_js.should eq(expected)
    end
  end
end
