#! /usr/bin/env ruby

require 'open3'
require 'json'
require 'yaml'
require 'gli'

class Spotifyfs
  def self.spotifycli(command)
    data = `spotifycli #{command}`.lines

    data.shift
    data.reject! {|l| l.strip.empty? }

    field_widths = data.first.split.map(&:size)

    data[3..-2].map do |line|
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
        "attributes" => { "size" => 4096 }, # This is rather expensive. Can we just guess about the size?
        "state"   => "{\"id\":\"#{entry[0]}\"}",
      }
    end
  end

  def self.get_track_by_id(id)
    data = spotifycli("show --tid '#{id}'").flatten

    txt  = data[1]
    txt << "\n#{'-'*data[1].size}\n"
    txt << "Album     : #{data[2]}\n"
    txt << "Artist    : #{data[3]}\n"
    txt << "Duration  : #{data[4]}\n"
    txt << "Popularity: #{data[5]}%\n"
    txt << "Explicit  : #{data[6]}\n"
    txt << "Track ID  : #{data[0]}\n"
    txt << "\n#{data[7]}\n" unless data[7].empty?
    txt
  end

  def self.get_track(playlist, track)
    list = spotifycli("list --p '#{playlist}'")
    tid  = list.find {|entry| entry[1] == track}

    self.get_track_by_id(tid[0])
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
      config = YAML.load_file(File.expand_path('.puppetlabs/wash/wash.yaml'))['spotify']
      ENV['SPOTIFY_ID']     = config['key']
      ENV['SPOTIFY_SECRET'] = config['secret']
    rescue
      # nop
    end
  end

  command :init do |c|
    c.action do |global_options,options,args|
      `spotifycli login` unless File.file?(File.expand_path('~/.sptok'))
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
      fs, namespace, playlist, track = self.tokenize(args.shift)
      state = JSON.parse(args.shift) rescue {}

      raise "This... can't happen?" unless fs == 'spotify'
      raise "Only support reading tracks" unless track

      if state.include? 'id'
        puts Spotifyfs.get_track_by_id(state['id'])
      else
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



