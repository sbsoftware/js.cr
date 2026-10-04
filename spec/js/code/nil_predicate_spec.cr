require "../../spec_helper"

module JS::Code::NilPredicateSpec
  class NilPredicateCode < JS::Code
    def_to_js do
      missing = response.nil?
      console.log(response.nil?)

      if response.nil?
        console.log("missing")
      end

      if response.nil? && ready || fallback.nil?
        return !result.nil?
      end
    end
  end

  describe "NilPredicateCode.to_js" do
    it "checks null and undefined in every expression position with safe boolean grouping" do
      expected = <<-JS.squish
      var missing;
      missing = response === null || response === undefined;
      console.log(response === null || response === undefined);
      if (response === null || response === undefined) {
        console.log("missing");
      }
      if ((((response === null || response === undefined) && ready) || (fallback === null || fallback === undefined))) {
        return !(result === null || result === undefined);
      }
      JS

      NilPredicateCode.to_js.should eq(expected)
      NilPredicateCode.to_js.should_not contain(" == null")
    end
  end
end
