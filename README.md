# wash-spotifyfs
Implements a Spotify filesystem for [Wash](https://github.com/puppetlabs/wash)

## Installing

This requires my own fork of [spotifycli](https://github.com/binford2k/spotifycli)
to be installed and on your `$PATH`. ([upstream pull requests](https://github.com/masroorhasan/spotifycli/pulls))

Then simply drop the `spotify.rb` script somewhere in your path.

## Configuring

First you'll need a Spotify account and to [register your application](https://beta.developer.spotify.com/dashboard/login).
You'll need the client `id` and `secret`.

Then configure your `~/.puppetlabs/wash/wash.yaml` with that info:

```
external-plugins:
  - script: '/Users/ben/bin/spotify.rb'
spotify:
  key: <Client ID from Spotify>
  secret: <Client Secret from Spotify>
```


## Using

Start Wash. You should see a top-level `spotify` filesystem. `cd` into that and
you'll see just one entry, `playlists`. At some point I might add more, but for
now, that's it.

If you `ls` the `playlists` directory, you'll get a listing of all your playlists
as directories. You can `cd` into any of them and `ls` to get a listing of all
the tracks in that playlist. You can also `cat` any track to get more information
about it.
