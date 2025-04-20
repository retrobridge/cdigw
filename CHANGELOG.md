# Changelog

<!--
Each new version should contain a heading with the version and release date.

Sub-headings should group changes by type. Types are:

* `Added`      - for new features.
* `Changed`    - for changes in existing functionality.
* `Deprecated` - for soon-to-be removed features.
* `Removed`    - for now removed features.
* `Fixed`      - for any bug fixes.
* `Security`   - in case of vulnerabilities.
-->


Unreleased
----------

[1.0.3] - 2025-04-20
--------------------

### Fixed

* For albums with multiple discs, requesting disc 2 or more would incorrectly
  return the data for disc 1. This affected CDDB and MSCD.
* CDDB over HTTP: Missing a trailing newline in the response broke some clients'
  ability to process the response, like Exact Audio Copy.

[1.0.2] - 2025-03-20
--------------------

### Added

* (CDDBP) `STAT` command to show basic server stats

### Changed

* (CDDBP) Handshake now required before `QUERY` or `READ`

### Internal

* Improve CDDBP session logging using log metadata, logging responses

[1.0.1] - 2025-03-11
--------------------

### Fixed

* (CDDBP) Response format when there's only one match for proto > 3
* Parsing MusicBrainz responses when there's no `date`

### Changed

* (CDDBP) Automatically disconnect sessions with too many errors

[1.0.0] - 2025-03-09
--------------------

Previously no version numbers were kept and releases were simply rolling.

Version 1.0.0 marks when the app is considered feature complete for known use cases
and stable. Features at this point include:

* CDDB querying over HTTP
* CDDB querying over TCP (CDDBP)
* CD lookup for Deluxe CD (default player in Windows 98, 2000, ME)
* Basic lookup history/stats
