module Feeds
  enum FeedType
    RSS
    Atom
    JSON
  end

  UTF8_BOM = "\xEF\xBB\xBF"

  NO_ROOT_ELEMENT_MSG = "No root element found"

  # XML root element names used for format detection
  RDF_ROOT  = "RDF"
  ATOM_ROOT = "feed"

  # Shared XML element & attribute names
  TITLE_ELEM     = "title"
  LINK_ELEM      = "link"
  AUTHOR_ELEM    = "author"
  CATEGORY_ELEM  = "category"
  GENERATOR_ELEM = "generator"
  NAME_ELEM      = "name"
  EMAIL_ELEM     = "email"
  URI_ELEM       = "uri"
  TYPE_ATTR      = "type"
  HREF_ATTR      = "href"
  TEXT_ATTR      = "text"
  VERSION_ATTR   = "version"

  module Namespaces
    # Canonical prefixes
    ITUNES     = "itunes"
    DC         = "dc"
    CONTENT    = "content"
    MEDIA      = "media"
    ATOM       = "atom"
    RDF        = "rdf"
    RSS        = "rss"
    FEEDBURNER = "feedburner"
    WFW        = "wfw"
    SLASH      = "slash"
    CC         = "cc"
    GEORSS     = "georss"
    PSC        = "psc"

    # Namespace URIs
    ITUNES_URI_1   = "http://www.itunes.com/DTDs/PodCast-1.0.dtd"
    ITUNES_URI_2   = "http://www.itunes.com/dtds/podcast-1.0.dtd"
    DC_URI_1       = "http://purl.org/dc/elements/1.1/"
    DC_URI_2       = "http://purl.org/dc/terms/"
    CONTENT_URI    = "http://purl.org/rss/1.0/modules/content/"
    MEDIA_URI_1    = "http://search.yahoo.com/mrss"
    MEDIA_URI_2    = "http://search.yahoo.com/mrss/"
    ATOM_URI       = "http://www.w3.org/2005/Atom"
    FEEDBURNER_URI = "http://rssnamespace.org/feedburner/ext/1.0"
    WFW_URI        = "http://wellformedweb.org/commentAPI/"
    SLASH_URI      = "http://purl.org/rss/1.0/modules/slash/"
    CC_URI         = "http://creativecommons.org/ns#license"
    GEORSS_URI     = "http://www.georss.org/georss"
    PSC_URI        = "http://podlove.org/simple-chapters"
    RDF_SYNTAX_URI = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    RDF_09_URI     = "http://channel.netscape.com/rdf/simple/0.9/"
    RDF_09B_URI    = "http://my.netscape.com/rdf/simple/0.9/"
    RDF_10_URI     = "http://purl.org/rss/1.0/"

    # URI to canonical prefix mapping
    MAPPING = {
      ITUNES_URI_1   => ITUNES,
      ITUNES_URI_2   => ITUNES,
      DC_URI_1       => DC,
      DC_URI_2       => DC,
      CONTENT_URI    => CONTENT,
      MEDIA_URI_1    => MEDIA,
      MEDIA_URI_2    => MEDIA,
      ATOM_URI       => ATOM,
      FEEDBURNER_URI => FEEDBURNER,
      WFW_URI        => WFW,
      SLASH_URI      => SLASH,
      CC_URI         => CC,
      GEORSS_URI     => GEORSS,
      PSC_URI        => PSC,
      RDF_SYNTAX_URI => RDF,
      RDF_10_URI     => RSS,
      RDF_09_URI     => RSS,
      RDF_09B_URI    => RSS,
    }

    # Prefixes already handled natively by each format parser
    RSS_KNOWN  = {"", ATOM, CONTENT, RDF, RSS}
    ATOM_KNOWN = {"", ATOM}

    def self.canonical_prefix(uri : String, declared : String) : String
      MAPPING[uri]? || declared
    end
  end

  module RSS
    VERSION_10 = "1.0"
    VERSION_09 = "0.9"

    CHANNEL_ELEM         = "channel"
    ITEM_ELEM            = "item"
    DESCRIPTION_ELEM     = "description"
    LANGUAGE_ELEM        = "language"
    COPYRIGHT_ELEM       = "copyright"
    MANAGING_EDITOR_ELEM = "managingEditor"
    WEB_MASTER_ELEM      = "webMaster"
    PUB_DATE_ELEM        = "pubDate"
    LAST_BUILD_DATE_ELEM = "lastBuildDate"
    IMAGE_ELEM           = "image"
    GUID_ELEM            = "guid"
    ENCLOSURE_ELEM       = "enclosure"
    ENCODED_ELEM         = "encoded"
    URL_ELEM             = "url"
    WIDTH_ELEM           = "width"
    HEIGHT_ELEM          = "height"

    DOMAIN_ATTR       = "domain"
    IS_PERMALINK_ATTR = "isPermalink"
    URL_ATTR          = "url"
    LENGTH_ATTR       = "length"
  end

  module Atom
    VERSION = "1.0"

    SUBTITLE_ELEM  = "subtitle"
    ID_ELEM        = "id"
    UPDATED_ELEM   = "updated"
    ICON_ELEM      = "icon"
    LOGO_ELEM      = "logo"
    RIGHTS_ELEM    = "rights"
    ENTRY_ELEM     = "entry"
    PUBLISHED_ELEM = "published"
    CONTENT_ELEM   = "content"
    SUMMARY_ELEM   = "summary"
    DIV_ELEM       = "div"

    LINK_ALTERNATE = "alternate"
    LINK_SELF      = "self"
    LINK_ENCLOSURE = "enclosure"
    XHTML_TYPE     = "xhtml"

    REL_ATTR      = "rel"
    HREFLANG_ATTR = "hreflang"
    TITLE_ATTR    = "title"
    LENGTH_ATTR   = "length"
    SRC_ATTR      = "src"
    TERM_ATTR     = "term"
    SCHEME_ATTR   = "scheme"
    LABEL_ATTR    = "label"
    LANG_ATTR     = "lang"
    URI_ATTR      = "uri"

    GENERATOR_VERSION_SEP = " v"
  end

  module JSON
    FEED_VERSION_11_URI = "jsonfeed.org/version/1.1"
    FEED_VERSION_1_URI  = "jsonfeed.org/version/1"

    FEED_VERSION_11 = "1.1"
    FEED_VERSION_10 = "1.0"

    PARSE_ERROR_PREFIX = "Invalid JSON: "
  end

  module ITunes
    AUTHOR           = "author"
    BLOCK            = "block"
    EXPLICIT         = "explicit"
    KEYWORDS         = "keywords"
    SUBTITLE         = "subtitle"
    SUMMARY          = "summary"
    COMPLETE         = "complete"
    NEW_FEED_URL     = "new-feed-url"
    TYPE             = "type"
    IMAGE            = "image"
    OWNER            = "owner"
    CATEGORY         = "category"
    DURATION         = "duration"
    CLOSED_CAPTIONED = "isClosedCaptioned"
    EPISODE          = "episode"
    SEASON           = "season"
    ORDER            = "order"
    EPISODE_TYPE     = "episodeType"
  end

  module DublinCore
    TITLE       = "title"
    CREATOR     = "creator"
    AUTHOR      = "author"
    SUBJECT     = "subject"
    DESCRIPTION = "description"
    PUBLISHER   = "publisher"
    CONTRIBUTOR = "contributor"
    DATE        = "date"
    TYPE        = "type"
    FORMAT      = "format"
    IDENTIFIER  = "identifier"
    SOURCE      = "source"
    LANGUAGE    = "language"
    RELATION    = "relation"
    COVERAGE    = "coverage"
    RIGHTS      = "rights"
  end
end
