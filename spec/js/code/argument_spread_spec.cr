require "../../spec_helper"

module JS::Code::ArgumentSpreadSpec
  class SpreadCode < JS::Code
    def_to_js do
      callback.call(first, *remaining)
      callback.call(*leading, middle, *trailing)
      callback.call(*load_arguments(source))
      widget = Widget.new(first, *remaining)
    end
  end

  describe "SpreadCode.to_js" do
    it "emits JavaScript spread in call and constructor arguments" do
      expected = <<-JS.squish
      var widget;
      callback.call(first, ...remaining);
      callback.call(...leading, middle, ...trailing);
      callback.call(...load_arguments(source));
      widget = new Widget(first, ...remaining);
      JS

      SpreadCode.to_js.should eq(expected)
    end

    it "rejects double splats with a clear error" do
      source = <<-CR
      require "./src/js"

      class DoubleSplatCode < JS::Code
        def_to_js do
          callback.call(**options)
        end
      end

      puts DoubleSplatCode.to_js
      CR

      exit_code, _stdout, stderr = crystal_eval(source)
      exit_code.should_not eq(0)
      stderr.should contain("Double splats are not supported in JavaScript call arguments")
    end
  end
end
