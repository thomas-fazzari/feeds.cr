# Feeds

[![CI](https://github.com/thomas-fazzari/feeds.cr/actions/workflows/ci.yml/badge.svg)](https://github.com/thomas-fazzari/feeds.cr/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/thomas-fazzari/feeds.cr/graph/badge.svg)](https://codecov.io/gh/thomas-fazzari/feeds.cr)

Universal feed parser for Crystal, inspired by [gofeed](https://github.com/mmcdole/gofeed).

## Installation

Add to your `shard.yml`:

```yaml
dependencies:
  feeds:
    github: thomas-fazzari/feeds.cr
```

Run `shards install`.

## Usage

```crystal
require "feeds"

feed = Feeds.parse(content)
feed.title # => "My Blog"
feed.feed_type # => Feeds::FeedType::RSS, ::Atom, or ::JSON
feed.items.each do |item|
  item.title
  item.link
  item.published_parsed # => Time?
  item.content
end
```

## Supported Formats

| Format    | Versions      |
| --------- | ------------- |
| RSS       | 0.9, 1.0, 2.0 |
| Atom      | 1.0           |
| JSON Feed | 1.0, 1.1      |

The parser detects the format automatically.

## Unified Model

Every feed normalizes to a common structure:

```crystal
feed.title                # => String?
feed.description          # => String?
feed.link                 # => String? (site URL)
feed.feed_link            # => String? (feed URL)
feed.language             # => String?
feed.authors              # => Array(Feeds::Person)
feed.image                # => Feeds::Image?
feed.published_parsed     # => Time?
feed.updated_parsed       # => Time?
feed.items                # => Array(Feeds::Item)
```

Each item exposes:

```crystal
item.title                # => String?
item.link                 # => String?
item.guid                 # => String?
item.content              # => String?
item.description          # => String?
item.published_parsed     # => Time?
item.updated_parsed       # => Time?
item.authors              # => Array(Feeds::Person)
item.categories           # => Array(String)
item.enclosures           # => Array(Feeds::Enclosure)
item.image                # => Feeds::Image?
```

## Extensions

The parser reads Dublin Core and iTunes podcast extensions from RSS and Atom feeds:

```crystal
feed.dublin_core_ext.try(&.creator)   # => Array(String)
feed.itunes_ext.try(&.author)         # => String?

item.itunes_ext.try(&.duration)       # => String?
item.itunes_ext.try(&.episode)        # => String?
```

Other namespace extensions are accessible via `extension_values`:

```crystal
feed.extension_values("media", "thumbnail")  # => Array(String)
```

## Error Handling

`Feeds.parse` raises `Feeds::UnknownFormatError` when the format cannot be detected, and `Feeds::ParseError` when the content is malformed. Invalid dates and missing optional fields never raise (they return `nil`).

```crystal
begin
  feed = Feeds.parse(content)
rescue Feeds::UnknownFormatError
  # not RSS, Atom, or JSON Feed
rescue Feeds::ParseError
  # malformed XML or JSON
end
```

## Dependencies

- [dateparse.cr](https://github.com/thomas-fazzari/dateparse.cr) (date/time parsing)

## License

[MIT](LICENSE)
