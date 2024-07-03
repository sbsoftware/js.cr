require "../../spec_helper"

module JS::Code::IfElseSpec
  class MyCode < JS::Code
    def_to_js do
      console.log(a) if a == 2

      if c > 3
        foo.bar = 7
        _literal_js("console.log(\"then\");")
      else
        foo.bar = 5
        _literal_js("console.log(\"else\");")
      end

      if something == "test"
        console.log("Yeah!")
      else
        if b == 1
          console.log("Booo!")
        end
      end

      if a == 7
        console.log("7")
      elsif a == 5
        console.log("5")
      else
        console.log("else")
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
        console.log("then");
      } else {
        foo.bar = 5;
        console.log("else");
      }

      if (something == "test") {
        console.log("Yeah!");
      } else {
        if (b == 1) {
          console.log("Booo!");
        }
      }

      if (a == 7) {
        console.log("7");
      } else {
        if (a == 5) {
          console.log("5");
        } else {
          console.log("else");
        }
      }
      JS

      MyCode.to_js.should eq(expected)
    end
  end
end
