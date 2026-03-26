require "../spec_helper"

module JSONFixtures
  def self.load(name)
    File.read(File.join(__DIR__, "../fixtures/json", name))
  end
end

describe Feeds::JSON::Parser do
  it "parses a v1.0 feed" do
    feed = Feeds::JSON::Parser.new.parse(JSONFixtures.load("feed_v1.json"))
    feed.feed_version.should eq("1.0")
    feed.title.should eq("JSON Feed Test")
    feed.link.should eq("https://example.com")
    feed.feed_link.should eq("https://example.com/feed.json")
    feed.description.should eq("A test JSON feed")
    feed.image.try(&.url).should eq("https://example.com/icon.png")
    feed.items.size.should eq(2)
  end

  it "parses feed-level author (v1.0 singular)" do
    feed = Feeds::JSON::Parser.new.parse(JSONFixtures.load("feed_v1.json"))
    author = feed.authors.first?
    author.should_not be_nil
    author.try(&.name).should eq("Jane Doe")
    author.try(&.uri).should eq("https://jane.example.com")
  end

  it "parses feed-level authors array (v1.1)" do
    feed = Feeds::JSON::Parser.new.parse(JSONFixtures.load("feed_v1.1.json"))
    feed.authors.size.should eq(2)
    feed.authors[0].name.should eq("Alice")
    feed.authors[1].name.should eq("Bob")
    feed.language.should eq("en-US")
  end

  it "parses item fields" do
    feed = Feeds::JSON::Parser.new.parse(JSONFixtures.load("feed_v1.json"))
    item = feed.items[0]
    item.guid.should eq("1")
    item.link.should eq("https://example.com/post/1")
    item.title.should eq("First Post")
    item.content.should eq("<p>Hello, world!</p>")
    item.description.should eq("A brief summary")
    item.image.try(&.url).should eq("https://example.com/post/1/image.png")
    item.published.should eq("2026-03-20T10:00:00Z")
    item.updated.should eq("2026-03-21T12:00:00Z")
    item.categories.should eq(["crystal", "rss"])
  end

  it "parses attachments" do
    feed = Feeds::JSON::Parser.new.parse(JSONFixtures.load("feed_v1.json"))
    enc = feed.items[0].enclosures.first?
    enc.should_not be_nil
    enc.try(&.url).should eq("https://example.com/post/1/audio.mp3")
    enc.try(&.type).should eq("audio/mpeg")
    enc.try(&.length).should eq("3600")
  end

  it "parses a minimal feed" do
    feed = Feeds::JSON::Parser.new.parse(JSONFixtures.load("feed_minimal.json"))
    feed.title.should eq("Minimal Feed")
    feed.items.size.should eq(0)
  end

  it "coerces numeric id to string" do
    feed = Feeds::JSON::Parser.new.parse(%({"version":"1","title":"t","items":[{"id":42}]}))
    feed.items[0].guid.should eq("42")
  end

  it "raises ParseError on invalid JSON" do
    expect_raises(Feeds::ParseError) do
      Feeds::JSON::Parser.new.parse("not json at all {{{")
    end
  end

  it "raises ParseError on empty string" do
    expect_raises(Feeds::ParseError) do
      Feeds::JSON::Parser.new.parse("")
    end
  end
end
