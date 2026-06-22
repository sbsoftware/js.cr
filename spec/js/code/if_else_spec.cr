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

  class ConditionalExpressionCode < JS::Code
    def_to_js do
      index = if event.params.placement == "bottom"
                1
              else
                0
              end
      let label = enabled ? "enabled" : "disabled"
      console.log(ready ? result : fallback)
      optional = if available
                   value
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

  describe "ConditionalExpressionCode.to_js" do
    it "emits JavaScript conditional operators when Crystal conditionals are used as expressions" do
      expected = <<-JS.squish
      var index;
      var optional;
      index = (event.params.placement == "bottom" ? 1 : 0);
      let label = (enabled ? "enabled" : "disabled");
      console.log((ready ? result : fallback));
      optional = (available ? value : undefined);
      JS

      ConditionalExpressionCode.to_js.should eq(expected)
      ConditionalExpressionCode.to_js.should_not contain("= if (")
    end
  end
end
