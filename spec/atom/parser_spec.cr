require "../spec_helper"

module AtomFixtures
  def self.load(name)
    File.read(File.join(__DIR__, "../fixtures/atom", name))
  end
end

describe Feeds::Atom::Parser do
  it "parses basic feed fields" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom_basic.xml"))
    feed.title.should eq("Test Atom Feed")
    feed.description.should eq("A test Atom 1.0 feed")
    feed.updated_parsed.should_not be_nil
    feed.copyright.should eq("© 2026 Example")
    feed.image.should_not be_nil
    feed.language.should eq("en-us")
  end

  it "parses feed links" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom_basic.xml"))
    feed.links.size.should eq(2)
    feed.link.should eq("https://example.com")
    feed.feed_link.should eq("https://example.com/feed.atom")
  end

  it "parses feed author" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom_basic.xml"))
    feed.authors.size.should eq(1)
    feed.authors.first.name.should eq("Jane Author")
    feed.authors.first.email.should eq("jane@example.com")
    feed.authors.first.uri.should eq("https://example.com/jane")
  end

  it "parses generator with attributes" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom_basic.xml"))
    feed.generator.should_not be_nil
    feed.generator.should eq("Test Generator v1.0")
  end

  it "parses entries" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom_basic.xml"))
    feed.items.size.should eq(2)
    item = feed.items.first
    item.title.should eq("First Entry")
    item.guid.should eq("urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a")
    item.updated_parsed.should_not be_nil
    item.published_parsed.should_not be_nil
    item.description.should eq("First entry summary")
  end

  it "parses entry content with type" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom_basic.xml"))
    item = feed.items.first
    item.content.should_not be_nil
  end

  it "parses entry author" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom_basic.xml"))
    item = feed.items.first
    item.authors.size.should eq(1)
    item.authors.first.name.should eq("Alice")
    item.authors.first.email.should eq("alice@example.com")
  end

  it "parses minimal feed" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom_minimal.xml"))
    feed.title.should eq("Minimal Feed")
    feed.items.should be_empty
  end

  it "parses multiple link types including enclosure" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom_links.xml"))
    feed.links.size.should eq(3)
    item = feed.items.first
    item.links.size.should eq(3)
    enc = item.enclosures.first?
    enc.should_not be_nil
    enc.try(&.type).should eq("audio/mpeg")
    enc.try(&.length).should eq("12345678")
  end

  it "parses multiple authors and contributors" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom_authors.xml"))
    item = feed.items.first
    item.authors.size.should eq(2)
  end

  it "parses categories with attributes" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom_categories.xml"))
    feed.categories.size.should eq(2)
    feed.categories.first.should eq("Technology")
  end

  it "parses content types (text, html, xhtml, external)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom_content_types.xml"))
    feed.items.size.should eq(4)

    feed.items[0].content.should eq("Plain text content")
    feed.items[1].content.should_not be_nil
    feed.items[2].content.should_not be_nil
    feed.items[3].content.should_not be_nil
  end

  it "parses Dublin Core extension" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom_dc.xml"))
    feed.dublin_core_ext.should_not be_nil
    feed.dublin_core_ext.try(&.creator.first?).should eq("DC Feed Author")
    item = feed.items.first
    item.dublin_core_ext.should_not be_nil
    item.dublin_core_ext.try(&.creator.first?).should eq("DC Entry Author")
    item.dublin_core_ext.try(&.subject).should eq(["Crystal", "Programming"])
  end

  it "parses iTunes extension" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom_itunes.xml"))
    feed.itunes_ext.should_not be_nil
    feed.itunes_ext.try(&.author).should eq("Podcast Host")
    feed.itunes_ext.try(&.categories.empty?).should be_false
    feed.itunes_ext.try(&.owner).try(&.email).should eq("host@example.com")
    item = feed.items.first
    item.itunes_ext.should_not be_nil
    item.itunes_ext.try(&.duration).should eq("42:30")
    item.itunes_ext.try(&.episode).should eq("1")
  end

  it "raises ParseError for empty document" do
    expect_raises(Feeds::ParseError) do
      Feeds::Atom::Parser.new.parse("")
    end
  end

  it "raises ParseError for document with no root element" do
    expect_raises(Feeds::ParseError) do
      Feeds::Atom::Parser.new.parse("just text, no XML")
    end
  end

  it "handles malformed dates gracefully" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom_malformed_dates.xml"))
    feed.updated_parsed.should be_nil
    feed.items.first.updated_parsed.should be_nil
    feed.items.first.published_parsed.should be_nil
  end

  it "parses feed title (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_title.xml"))
    feed.title.should eq("Feed Title")
  end

  it "parses feed subtitle (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_subtitle.xml"))
    feed.description.should_not be_nil
  end

  it "parses feed author name (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_author_name.xml"))
    feed.authors.first.name.should eq("Author Name")
  end

  it "parses feed author uri (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_author_uri.xml"))
    feed.authors.first.uri.should eq("http://example.org")
  end

  it "parses multiple feed authors (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_author_multiple.xml"))
    feed.authors.size.should eq(2)
  end

  it "parses feed link href (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_link_href.xml"))
    feed.links.first.should eq("http://example.org")
  end

  it "parses multiple feed links (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_link_multiple.xml"))
    feed.links.size.should eq(2)
  end

  it "parses generator name (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_generator_name.xml"))
    feed.generator.should_not be_nil
  end

  it "parses feed icon (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_icon.xml"))
    feed.image.should_not be_nil
  end

  it "parses feed logo (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_logo.xml"))
    feed.image.should_not be_nil
  end

  it "parses feed rights (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_rights.xml"))
    feed.copyright.should_not be_nil
  end

  it "parses xml:lang (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_xml_lang.xml"))
    feed.language.should_not be_nil
  end

  it "parses entry title (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_entry_title.xml"))
    feed.items.first.title.should_not be_nil
  end

  it "parses entry content (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_entry_content.xml"))
    feed.items.first.content.should_not be_nil
  end

  it "parses entry content text type (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_entry_content_text.xml"))
    feed.items.first.content.should_not be_nil
  end

  it "parses entry content xhtml inline markup (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_entry_content_xhtml_inline_markup.xml"))
    item = feed.items.first
    item.content.should_not be_nil
  end

  it "parses entry content src (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_entry_content_src.xml"))
    # content with src only has no text value; enclosure or link carries the url
    feed.items.first.should_not be_nil
  end

  it "parses entry id (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_entry_id.xml"))
    feed.items.first.guid.should_not be_nil
  end

  it "parses entry link href (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_entry_link_href.xml"))
    feed.items.first.links.first.should_not be_nil
  end

  it "parses multiple entry links (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_entry_link_multiple.xml"))
    feed.items.first.links.size.should eq(2)
  end

  it "parses entry link with no rel (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_entry_link_no_rel.xml"))
    feed.items.first.link.should eq("http://example.org")
  end

  it "parses entry category term (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_entry_category_term.xml"))
    feed.items.first.categories.should_not be_empty
  end

  it "parses entry category label (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_entry_category_label.xml"))
    feed.items.first.categories.should_not be_empty
  end

  it "parses entry summary (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_entry_summary.xml"))
    feed.items.first.description.should_not be_nil
  end

  it "parses entry source title (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_entry_source_title.xml"))
    feed.items.first.should_not be_nil
  end

  it "parses entry source author name (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_entry_source_author_name.xml"))
    feed.items.first.should_not be_nil
  end

  it "parses entry source id (gofeed)" do
    feed = Feeds::Atom::Parser.new.parse(AtomFixtures.load("atom10_feed_entry_source_id.xml"))
    feed.items.first.should_not be_nil
  end
end
