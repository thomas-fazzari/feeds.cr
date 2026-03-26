require "../spec_helper"

describe Feeds::RSS::GUID do
  it "stores value and permalink flag" do
    g = Feeds::RSS::GUID.new
    g.value.should be_nil
    g.is_permalink.should be_nil
  end
end

describe Feeds::RSS::Category do
  it "can be instantiated" do
    cat = Feeds::RSS::Category.new
    cat.domain.should be_nil
    cat.value.should be_nil
  end
end
