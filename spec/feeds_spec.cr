require "./spec_helper"

describe Feeds do
  describe "Feed" do
    it "can be instantiated with defaults" do
      feed = Feeds::Feed.new(Feeds::FeedType::RSS)
      feed.title.should be_nil
      feed.feed_type.should eq(Feeds::FeedType::RSS)
      feed.feed_version.should eq("")
      feed.items.should be_a(Array(Feeds::Item))
      feed.items.should be_empty
      feed.authors.should be_a(Array(Feeds::Person))
      feed.categories.should be_a(Array(String))
      feed.links.should be_a(Array(String))
      feed.extensions.should be_a(Hash(String, Hash(String, Array(Feeds::Extension))))
    end

    it "items are independent between instances" do
      f1 = Feeds::Feed.new(Feeds::FeedType::RSS)
      f2 = Feeds::Feed.new(Feeds::FeedType::RSS)
      f1.items << Feeds::Item.new
      f2.items.should be_empty
    end
  end

  describe "Item" do
    it "can be instantiated with defaults" do
      item = Feeds::Item.new
      item.title.should be_nil
      item.enclosures.should be_a(Array(Feeds::Enclosure))
      item.enclosures.should be_empty
      item.links.should be_a(Array(String))
      item.authors.should be_a(Array(Feeds::Person))
    end
  end

  describe "Extension" do
    it "can be instantiated with defaults" do
      ext = Feeds::Extension.new
      ext.name.should eq("")
      ext.value.should eq("")
      ext.attrs.should be_empty
      ext.children.should be_empty
    end

    it "holds name and value" do
      ext = Feeds::Extension.new
      ext.name = "creator"
      ext.value = "Alice"
      ext.name.should eq("creator")
      ext.value.should eq("Alice")
    end
  end

  describe "DublinCoreExtension" do
    it "has empty arrays by default" do
      dc = Feeds::DublinCoreExtension.new
      dc.title.should be_empty
      dc.creator.should be_empty
      dc.date.should be_empty
      dc.rights.should be_empty
    end
  end

  describe "ITunesFeedExtension" do
    it "has nil fields by default" do
      itunes = Feeds::ITunesFeedExtension.new
      itunes.author.should be_nil
      itunes.explicit.should be_nil
      itunes.owner.should be_nil
      itunes.keywords.should be_nil
      itunes.categories.should be_a(Array(Feeds::ITunesCategory))
      itunes.categories.should be_empty
    end
  end

  describe "ITunesItemExtension" do
    it "has nil fields by default" do
      itunes = Feeds::ITunesItemExtension.new
      itunes.duration.should be_nil
      itunes.episode.should be_nil
    end
  end

  describe "ITunesOwner" do
    it "can be instantiated" do
      owner = Feeds::ITunesOwner.new
      owner.name.should be_nil
      owner.email.should be_nil
    end
  end

  describe "ITunesCategory" do
    it "can be instantiated" do
      cat = Feeds::ITunesCategory.new
      cat.text.should eq("")
      cat.subcategory.should be_nil
    end
  end

  describe "Person" do
    it "can be instantiated" do
      p = Feeds::Person.new
      p.name.should be_nil
      p.email.should be_nil
      p.uri.should be_nil
    end
  end

  describe "Image" do
    it "can be instantiated" do
      img = Feeds::Image.new
      img.url.should be_nil
      img.title.should be_nil
    end
  end

  describe "Enclosure" do
    it "can be instantiated" do
      enc = Feeds::Enclosure.new
      enc.url.should be_nil
      enc.length.should be_nil
    end
  end
end
