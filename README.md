# CDIGW: CD Info Gateway

![Tests](https://github.com/retrobridge/cdigw/workflows/Tests/badge.svg)

On 31 March 2020, [FreeDB] shut down its service.

To continue to support older CD player software, this gateway will accept
CDDB queries, look up the CDs on [MusicBrainz], and reply in CDDB format.

**WORK IN PROGRESS**: This is currently a WIP, not setup live anywhere.
Just trying some different players and using proxies to see how they talk.
The code is sloppy and in "hacking it out" mode.

## Tested CD players

### IRIX 6.5 CDplayer

The default CDplayer (`cdman`) on IRIX 6.5 uses CDDB protocol v5 over HTTP.
The *Options > FreeDB Setup* menu lets you easily change the server and port.

### cdrdao 1.2.4

Linux utility. Uses CDDB protocol v1. By default uses `cddbp` but `http` can
be used with the `--cddb-servers` argument.

Usage:

    cdrdao read-cddb --cddb-servers <host>:<port>:<path> mycd.toc

[FreeDB]: http://www.freedb.org
[MusicBrainz]: https://musicbrainz.org
