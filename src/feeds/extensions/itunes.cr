module Feeds
  class ITunesOwner
    property name : String?
    property email : String?

    def initialize(@name = nil, @email = nil)
    end
  end

  # An iTunes category with an optional single subcategory
  class ITunesCategory
    property text : String = ""
    property subcategory : ITunesCategory?

    def initialize(@text = "", @subcategory = nil)
    end
  end

  # iTunes podcast extension fields at the feed level
  class ITunesFeedExtension
    property author : String?
    property block : String? # "yes" blocks the feed from the iTunes Store
    property categories : Array(ITunesCategory) = [] of ITunesCategory
    property image : String?
    property explicit : String?
    property complete : String?
    property new_feed_url : String?
    property owner : ITunesOwner?
    property keywords : String?
    property subtitle : String?
    property summary : String?
    property type : String? # "episodic" or "serial"
  end

  # iTunes podcast extension fields at the item level
  class ITunesItemExtension
    property author : String?
    property block : String? # "yes" blocks this episode from the iTunes Store
    property closed_captioned : String?
    property duration : String?
    property explicit : String?
    property keywords : String?
    property order : String?
    property subtitle : String?
    property summary : String?
    property image : String?
    property season : String?
    property episode : String?
    property episode_type : String? # "full", "trailer", or "bonus"
  end
end
