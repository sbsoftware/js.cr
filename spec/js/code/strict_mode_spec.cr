require "../../spec_helper"

module JS::Code::StrictModeSpec
  class StrictCode < JS::Code
    js_alias "doc", "document"

    def_to_js strict: true do
      doc.querySelector("body")
      JS::Browser::Console.info("ready")
    end
  end

  class LooseCode < JS::Code
    def_to_js do
      undeclaredThing.callMe._call
    end
  end

  describe "strict mode" do
    it "allows declared externs and typed wrappers" do
      expected = <<-JS.squish
      document.querySelector("body");
      console.info("ready");
      JS

      StrictCode.to_js.should eq(expected)
    end

    it "keeps loose mode backwards-compatible" do
      expected = <<-JS.squish
      undeclaredThing.callMe();
      JS

      LooseCode.to_js.should eq(expected)
    end

    it "fails on undeclared identifiers in strict mode" do
      source = <<-CR
      require "./src/js"

      class StrictFailureCode < JS::Code
        def_to_js strict: true do
          missing_api._call
        end
      end

      puts StrictFailureCode.to_js
      CR

      exit_code, _stdout, stderr = crystal_eval(source)
      exit_code.should_not eq(0)
      stderr.should contain("Strict mode: undeclared JS identifier")
      stderr.should contain("missing_api")
      stderr.should contain("js_alias")
    end

    it "fails on _literal_js in strict mode" do
      source = <<-CR
      require "./src/js"

      class StrictLiteralCode < JS::Code
        def_to_js strict: true do
          _literal_js("alert('nope')")
        end
      end

      puts StrictLiteralCode.to_js
      CR

      exit_code, _stdout, stderr = crystal_eval(source)
      exit_code.should_not eq(0)
      stderr.should contain("Strict mode forbids `_literal_js(...)`")
    end
  end
end
