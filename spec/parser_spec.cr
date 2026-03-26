require "./spec_helper"

module ParserFixtures
  def self.rss
    File.read(File.join(__DIR__, "fixtures/rss/rss2_basic.xml"))
  end

  def self.atom
    File.read(File.join(__DIR__, "fixtures/atom/atom_basic.xml"))
  end

  def self.json
    File.read(File.join(__DIR__, "fixtures/json/feed_v1.json"))
  end
end

describe Feeds::Parser do
  describe "#parse" do
    it "parses RSS content via auto-detection" do
      feed = Feeds::Parser.new.parse(ParserFixtures.rss)
      feed.feed_type.should eq(Feeds::FeedType::RSS)
      feed.title.should eq("Test Feed")
    end

    it "parses Atom content via auto-detection" do
      feed = Feeds::Parser.new.parse(ParserFixtures.atom)
      feed.feed_type.should eq(Feeds::FeedType::Atom)
      feed.title.should eq("Test Atom Feed")
    end

    it "parses JSON Feed content via auto-detection" do
      feed = Feeds::Parser.new.parse(ParserFixtures.json)
      feed.feed_type.should eq(Feeds::FeedType::JSON)
      feed.title.should eq("JSON Feed Test")
    end

    it "raises UnknownFormatError for invalid content" do
      expect_raises(Feeds::UnknownFormatError) do
        Feeds::Parser.new.parse("<html><body>Not a feed</body></html>")
      end
    end

    it "raises UnknownFormatError for empty document" do
      expect_raises(Feeds::UnknownFormatError) do
        Feeds::Parser.new.parse("")
      end
    end
  end
end

describe "Feeds.parse" do
  it "is a convenience for Parser.new.parse" do
    feed = Feeds.parse(ParserFixtures.rss)
    feed.feed_type.should eq(Feeds::FeedType::RSS)
    feed.title.should eq("Test Feed")
  end
end
