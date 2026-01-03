require "../../spec_helper"

module JS::Code::NilSpec
  class NilCode < JS::Code
    def_to_js do
      obj.some_prop = nil
      console.log(nil)
      arr = [nil, 1]
      hash = {foo: nil}
      nil
    end
  end

  describe "NilCode.to_js" do
    it "transpiles nil to undefined" do
      expected = <<-JS.squish
      var arr;
      var hash;
      obj.some_prop = undefined;
      console.log(undefined);
      arr = [undefined, 1];
      hash = {foo: undefined};
      undefined;
      JS

      NilCode.to_js.should eq(expected)
    end
  end
end
