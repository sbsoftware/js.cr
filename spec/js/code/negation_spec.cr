require "../../spec_helper"

module JS::Code::NegationSpec
  class NegationCode < JS::Code
    def_to_js do
      hidden = !name.textContent.trim._call.toLowerCase._call.includes(search)
      enabled = !settings.disabled
      visible = !!element.hidden
      grouped = !(ready || pending)
      different = !(left == right)

      if !items.includes(value)
        result = !check._call
      end
    end
  end

  describe "NegationCode.to_js" do
    it "recursively translates negated expressions in assignments and conditions" do
      expected = <<-JS.squish
      var hidden;
      var enabled;
      var visible;
      var grouped;
      var different;

      hidden = !name.textContent.trim().toLowerCase().includes(search);
      enabled = !settings.disabled;
      visible = !!element.hidden;
      grouped = !(ready || pending);
      different = !(left == right);
      if (!items.includes(value)) {
        result = !check();
      }
      JS

      NegationCode.to_js.should eq(expected)
    end

    it "executes a translated negated call" do
      javascript = <<-JS + NegationCode.to_js + <<-JS
      const name = {textContent: "  HELLO  "};
      const search = "hello";
      const settings = {disabled: false};
      const element = {hidden: false};
      const ready = false;
      const pending = false;
      const left = 1;
      const right = 2;
      const items = {includes: (value) => value === "present"};
      const value = "present";
      const check = () => true;
      JS
      if (hidden !== false) process.exit(1);
      JS
      status = Process.run("node", ["-e", javascript])

      status.success?.should be_true
    end
  end
end
