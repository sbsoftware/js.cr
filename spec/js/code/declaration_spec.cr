require "../../spec_helper"

module JS::Code::DeclarationSpec
  class DeclarationCode < JS::Code
    def_to_js do
      let branch_value
      if condition
        branch_value = "available"
      end
      console.log(branch_value)

      let pending
      pending = true
      console.log(pending)

      let counter = 0
      counter = counter + 1

      const label = "stable"
      console.log(label)
    end
  end

  class StrictDeclarationCode < JS::Code
    def_to_js strict: true do
      let maybe_value
      console.log(maybe_value)

      const fixed_value = "fixed"
      console.log(fixed_value)
    end
  end

  class NestedCallbackDeclarationCode < JS::Code
    def_to_js do
      let count = 0
      const label = "tick"

      setTimeout do
        count = count + 1
        console.log(label)
        console.log(count)
      end
    end
  end

  describe "let / const declarations" do
    it "emits let and const declarations at the declaration site" do
      expected = <<-JS.squish
      let branch_value;
      if (condition) {
        branch_value = "available";
      }
      console.log(branch_value);
      let pending;
      pending = true;
      console.log(pending);
      let counter = 0;
      counter = counter + 1;
      const label = "stable";
      console.log(label);
      JS

      DeclarationCode.to_js.should eq(expected)
      DeclarationCode.to_js.should_not contain("var pending;")
      DeclarationCode.to_js.should_not contain("var counter;")
    end

    it "keeps declared variables usable in strict mode" do
      expected = <<-JS.squish
      let maybe_value;
      console.log(maybe_value);
      const fixed_value = "fixed";
      console.log(fixed_value);
      JS

      StrictDeclarationCode.to_js.should eq(expected)
    end

    it "fails at compile-time when const has no initializer" do
      source = <<-CR
      require "./src/js"

      class InvalidConstCode < JS::Code
        def_to_js do
          const declared_without_value
        end
      end

      puts InvalidConstCode.to_js
      CR

      exit_code, _stdout, stderr = crystal_eval(source)
      exit_code.should_not eq(0)
      stderr.should contain("requires an initializer")
      stderr.should contain("const my_var = value")
    end

    it "fails at compile-time when using two call arguments" do
      source = <<-CR
      require "./src/js"

      class InvalidLetCallStyleCode < JS::Code
        def_to_js do
          let(my_var, 1)
        end
      end

      puts InvalidLetCallStyleCode.to_js
      CR

      exit_code, _stdout, stderr = crystal_eval(source)
      exit_code.should_not eq(0)
      stderr.should contain("accepts exactly one argument")
      stderr.should contain("let my_var = value")
    end

    it "keeps let/const bindings available inside nested callback functions" do
      expected = <<-JS.squish
      let count = 0;
      const label = "tick";
      setTimeout(function() {
        count = count + 1;
        console.log(label);
        console.log(count);
      });
      JS

      NestedCallbackDeclarationCode.to_js.should eq(expected)
      NestedCallbackDeclarationCode.to_js.should_not contain("var count;")
    end
  end
end
