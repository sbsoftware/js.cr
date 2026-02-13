require "../../spec_helper"

module JS::File::StrictModeSpec
  class StrictFile < JS::File
    js_alias "doc", "document"

    def_to_js strict: true do
      doc.body.classList.add("active")
    end
  end

  describe "StrictFile.to_js" do
    it "supports strict mode opt-in" do
      expected = <<-JS.squish
      document.body.classList.add("active");
      JS

      StrictFile.to_js.should eq(expected)
    end
  end
end
