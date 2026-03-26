require "../spec_helper"

module RSSFixtures
  def self.load(name)
    File.read(File.join(__DIR__, "../fixtures/rss", name))
  end
end

describe Feeds::RSS::Parser do
  it "parses RSS 2.0 basic channel fields" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss2_basic.xml"))
    feed.feed_version.should eq("2.0")
    feed.title.should eq("Test Feed")
    feed.link.should eq("https://example.com")
    feed.description.should eq("A test RSS 2.0 feed")
    feed.language.should eq("en-us")
    feed.copyright.should eq("© 2026 Example")
    feed.generator.should eq("Test Generator 1.0")
    feed.published.should_not be_nil
    feed.published_parsed.should_not be_nil
  end

  it "parses RSS 2.0 items" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss2_basic.xml"))
    feed.items.size.should eq(2)
    item = feed.items.first
    item.title.should eq("First Item")
    item.link.should eq("https://example.com/1")
    item.published_parsed.should_not be_nil
    item.guid.should eq("https://example.com/1")
  end

  it "parses RSS 2.0 image" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss2_image.xml"))
    feed.image.should_not be_nil
    feed.image.try(&.url).should_not be_nil
    feed.image.try(&.title).should_not be_nil
  end

  it "parses iTunes extension" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss2_itunes.xml"))
    feed.itunes_ext.should_not be_nil
    feed.itunes_ext.try(&.author).should eq("John Podcaster")
    feed.itunes_ext.try(&.categories.empty?).should be_false
    feed.itunes_ext.try(&.owner).try(&.email).should eq("john@example.com")
    item = feed.items.first
    item.itunes_ext.should_not be_nil
    item.itunes_ext.try(&.duration).should eq("42:30")
    item.itunes_ext.try(&.episode).should eq("1")
    item.itunes_ext.try(&.season).should eq("1")
  end

  it "parses Dublin Core extension" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss2_dc.xml"))
    feed.dublin_core_ext.should_not be_nil
    feed.dublin_core_ext.try(&.creator.empty?).should be_false
    item = feed.items.first
    item.dublin_core_ext.should_not be_nil
    item.dublin_core_ext.try(&.creator.first?).should eq("Alice")
  end

  it "parses content:encoded" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss2_content.xml"))
    feed.items.first.content.should_not be_nil
  end

  it "detects RSS 1.0 version" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss1_basic.xml"))
    feed.feed_version.should eq("1.0")
  end

  it "detects RSS 0.91 version" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss091_basic.xml"))
    feed.feed_version.should eq("0.91")
  end

  it "parses GUID with isPermalink=false" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss2_basic.xml"))
    feed.items[1].guid.should eq("item-id-002")
  end

  it "handles malformed dates gracefully" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss2_malformed_dates.xml"))
    feed.items.each do |item|
      item.published_parsed.should be_nil
    end
  end

  it "parses RSS 2.0 enclosures" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss2_enclosures.xml"))
    feed.items.first.enclosures.should_not be_empty
    enc = feed.items.first.enclosures.first
    enc.url.should_not be_nil
    enc.type.should_not be_nil
  end

  it "parses channel categories" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss2_categories.xml"))
    feed.categories.should_not be_empty
  end

  it "raises ParseError for empty document" do
    expect_raises(Feeds::ParseError) do
      Feeds::RSS::Parser.new.parse("")
    end
  end

  it "raises ParseError for document with no root element" do
    expect_raises(Feeds::ParseError) do
      Feeds::RSS::Parser.new.parse("just text, no XML")
    end
  end

  it "parses RSS 1.0 with Dublin Core" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss1_dc.xml"))
    feed.dublin_core_ext.should_not be_nil
    feed.dublin_core_ext.try(&.creator.first?).should eq("DC Author")
  end

  it "maps managing_editor to authors" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss2_basic.xml"))
    feed.authors.size.should eq(1)
    feed.authors.first.email.should eq("editor@example.com")
    feed.authors.first.name.should eq("Jane Editor")
  end

  it "maps pub_date to published_parsed" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss2_basic.xml"))
    feed.published_parsed.should_not be_nil
  end

  it "maps image to Feeds::Image" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss2_image.xml"))
    img = feed.image
    img.should_not be_nil
    img.try(&.url).should_not be_nil
  end

  it "maps enclosures to Feeds::Enclosure" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss2_enclosures.xml"))
    enc = feed.items.first.enclosures.first
    enc.url.should_not be_nil
    enc.type.should_not be_nil
  end

  it "maps item author to Feeds::Person" do
    feed = Feeds::RSS::Parser.new.parse(RSSFixtures.load("rss2_basic.xml"))
    item = feed.items.first
    item.authors.size.should eq(1)
    item.authors.first.email.should eq("author@example.com")
  end
end
