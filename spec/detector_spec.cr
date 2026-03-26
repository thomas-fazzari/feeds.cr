require "./spec_helper"

describe Feeds::Detector do
  it "detects RSS 2.0" do
    Feeds::Detector.detect(%(<rss version="2.0"><channel></channel></rss>)).should eq(Feeds::FeedType::RSS)
  end

  it "detects RSS 1.0 (RDF)" do
    content = %(<?xml version="1.0"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"></rdf:RDF>)
    Feeds::Detector.detect(content).should eq(Feeds::FeedType::RSS)
  end

  it "detects Atom" do
    content = %(<feed xmlns="http://www.w3.org/2005/Atom"><title>Test</title></feed>)
    Feeds::Detector.detect(content).should eq(Feeds::FeedType::Atom)
  end

  it "detects JSON Feed" do
    Feeds::Detector.detect(%({"version": "https://jsonfeed.org/version/1"})).should eq(Feeds::FeedType::JSON)
  end

  it "detects JSON Feed with leading whitespace" do
    Feeds::Detector.detect(%(   {"version": "1"})).should eq(Feeds::FeedType::JSON)
  end

  it "detects JSON Feed with UTF-8 BOM" do
    Feeds::Detector.detect("\xEF\xBB\xBF{\"version\": \"1\"}").should eq(Feeds::FeedType::JSON)
  end

  it "detects JSON Feed with BOM and whitespace" do
    Feeds::Detector.detect("\xEF\xBB\xBF  {\"version\": \"1\"}").should eq(Feeds::FeedType::JSON)
  end

  it "raises UnknownFormatError for HTML" do
    expect_raises(Feeds::UnknownFormatError) do
      Feeds::Detector.detect("<html><body></body></html>")
    end
  end

  it "raises UnknownFormatError for empty string" do
    expect_raises(Feeds::UnknownFormatError) do
      Feeds::Detector.detect("")
    end
  end

  it "detects RSS 1.0 (RDF) with feedburner extension" do
    content = <<-XML
      <?xml version="1.0"?>
      <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
               xmlns:feedburner="http://rssnamespace.org/feedburner/ext/1.0">
        <feedburner:info uri="test"/>
      </rdf:RDF>
      XML
    Feeds::Detector.detect(content).should eq(Feeds::FeedType::RSS)
  end

  it "raises UnknownFormatError for invalid XML" do
    expect_raises(Feeds::UnknownFormatError) do
      Feeds::Detector.detect("<<not valid xml>>")
    end
  end
end
