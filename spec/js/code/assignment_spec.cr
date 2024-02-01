require "../../spec_helper"

module JS::Code::AssignmentSpec
  class MyCode < JS::Code
    def_to_js do
      my_var = 1
      my_var += 1

      bla = false
      someArr = ["test", "blah", "foo"]
      someArr.forEach do |item|
        tmp = item
        if !bla
          console.log(tmp)
          bla = true
        end
      end
    end

    describe "MyCode.to_js" do
      it "return the correct JS code" do
        expected = <<-JS.squish
        var my_var;
        var bla;
        var someArr;
        my_var = 1;
        my_var = my_var + 1;
        bla = false;
        someArr = ["test", "blah", "foo"];
        someArr.forEach(function(item) {
          var tmp;
          tmp = item;
          if (!bla) {
            console.log(tmp);
            bla = true;
          }
        });
        JS

        MyCode.to_js.should eq(expected)
      end
    end
  end
end
