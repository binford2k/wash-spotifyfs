#! /usr/bin/env ruby

require 'open3'
require 'json'
require 'yaml'
require 'gli'

class Spotifyfs
  def self.spotifycli(command)
    data = `spotifycli #{command}`.lines
    data.shift

    field_widths = data.first.split.map(&:size)

    data[3..-3].map do |line|
      field_widths.map do |width|
        line.slice!(0, width+2).strip
      end
    end
  end

  def self.get_playlists
    data = spotifycli('playlists')
    data.map do |entry|
      {
        "name"    => entry[1],
        "methods" => ["list"],
      }
    end
  end

  def self.get_playlist_contents(playlist)
    data = spotifycli("list --p '#{playlist}'")
    data.map do |entry|
      {
        "name"    => entry[1],
        "methods" => ["read"],
        "attributes" => { "size" => `spotifycli show --tid #{entry[0]}`.size }, # This is rather expensive. Can we just guess about the size?
        "state"   => "{\"id\":\"#{entry[0]}\"}",
      }
    end
  end

  def self.get_track(playlist, track)
    # TODO: Use state, so that we don't have to list the playlist again here
    list = spotifycli("list --p '#{playlist}'")
    tid  = list.find {|entry| entry[1] == track}

    `spotifycli show --tid '#{tid[0]}'`
  end

  def self.get_namespaces
    [{
      "name"       => "playlists",
      "methods"    => ["list"],
      "cache_ttls" => {
                        "list" => 30
                      }
    }]
  end

  def self.get_root
    {
      "name"       => "spotify",
      "methods"    => ["list"],
      "cache_ttls" => {
                        "list" => 30
                      }
    }
  end

end

class App
  extend GLI::App

  program_desc 'A Spotify filesystem provider for Wash'

  def self.tokenize(path)
    path.split('/').reject {|entry| entry.empty?}
  end

  pre do |global_options,command,options,args|
    begin
      config = YAML.load_file(File.expand_path('.puppetlabs/wash/wash.yaml'))['spotifyfs']
      ENV['SPOTIFY_ID']     = config['key']
      ENV['SPOTIFY_SECRET'] = config['secret']
    rescue
      # nop
    end

  end

  command :init do |c|
    c.action do |global_options,options,args|
      puts Spotifyfs.get_root.to_json
    end
  end

  command :list do |c|
    c.action do |global_options,options,args|
      fs, namespace, playlist = self.tokenize(args.first)

      raise "This... can't happen?" unless fs == 'spotify'

      # only two cases, listing playlists or listing the contents of a playlist
      if playlist
        puts Spotifyfs.get_playlist_contents(playlist).to_json
      elsif namespace
        case namespace
          when 'playlists'
            puts Spotifyfs.get_playlists.to_json
          else
            raise "Namespace #{namespace} unsupported"
        end
      else
        puts Spotifyfs.get_namespaces.to_json
      end
    end
  end

  command :read do |c|
    c.action do |global_options,options,args|
      fs, namespace, playlist, track = self.tokenize(args.first)

      raise "This... can't happen?" unless fs == 'spotify'

      if track
        puts Spotifyfs.get_track(playlist, track)
      end
    end
  end

  command :metadata do |c|
    c.action do |global_options,options,args|
      puts {}.to_json
    end
  end

  command :stream do |c|
    c.action do |global_options,options,args|
      puts {}.to_json
    end
  end

  command :exec do |c|
    c.action do |global_options,options,args|
      puts {}.to_json
    end
  end

end

exit App.run(ARGV)



