# CDDB

## Access

CDDB can be accessed with `cddbp` or `http`.

### CDDB

Custom protocol for talking to the server, expected on port 888

Clients like `cdrdao` use this by default.

### HTTP

HTTP is expected on port 80 but many clients can configure a port.
The endpoint is expected to be at `/~cddb/cddb.cgi` and some clients have
this hardcoded, so it's best to stick to.

## Protocol Levels

The original protocol specifications are in the `CDDBPROTO` file.
This is a quick summary of the protocol levels with info relevant to this app.

### Level 4

The `cddb query` command now returns multiple matches.
Response code is `210` instead of `200`

Previously:

    200 data 940aac0d Marina & The Diamonds / The Family Jewels

Level 4 and above:

    210 Found exact matches, list follows (until terminating `.')
    data 940aac0d Marina & The Diamonds / The Family Jewels
    misc 940aac0d Marina & The Diamonds / The Family Jewels
    rock 940aac0d Marina & the Diamonds / The Family Jewels

### Level 5

`DGENRE` and `DYEAR` added to `cddb read` responses

### Level 6

Responses are *UTF-8* instead of *ISO-8859-1*
