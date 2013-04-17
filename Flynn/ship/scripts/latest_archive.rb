#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'plist'
require 'pp'

XCODE_ARCHIVE_BASE = "#{ENV['HOME']}/Library/Developer/Xcode/Archives"

def archive_get_bundle_info (archive_path)
  info = Plist::parse_xml("#{archive_path}/Info.plist")
  info[:archive_path] = archive_path
  return info
end

def archive_info_get_product_name (info)
  return info['Name']
end

def archive_info_get_bundle_id (info)
  return ((app = info['ApplicationProperties']) != nil) ? app['CFBundleIdentifier'] : nil
end

options = {}

OptionParser.new do |opts|
  
  opts.banner = "Usage: latest_build.rb [options]"

  opts.on("-n NAME", "--name NAME", "Find an archive by project name") do |name|
    options[:product_name] = name
  end
  
  opts.on("-b BUNDLE", "--bundle BUNDLE", "Find an archive by bundle identifier") do |bundle_id|
    options[:bundle_id] = bundle_id
  end
  
end.parse!

if options[:product_name] == nil && options[:bundle_id] == nil
  STDERR.puts "You must provide either a product name or bundle identifier to search for."
  STDERR.puts "Usage: #{ARGV[0]} -n <Project Name>"
  STDERR.puts "   or: #{ARGV[0]} -b <product.bundle.Identifier>"
  exit -1
end

candidates = []

Dir.foreach(XCODE_ARCHIVE_BASE) do |file1|
  if file1 !~ /^\./
    absolute1 = "#{XCODE_ARCHIVE_BASE}/#{file1}"
    Dir.foreach(absolute1) do |file2|
      if file2 =~ /\.xcarchive$/
        absolute2 = "#{absolute1}/#{file2}"
        info = archive_get_bundle_info(absolute2)
        if options[:bundle_id] != nil && archive_info_get_bundle_id(info) == options[:bundle_id]
          candidates << info
        elsif options[:product_name] != nil && archive_info_get_product_name(info) == options[:product_name]
          candidates << info
        end
      end
    end
  end
end

if candidates.length < 1
  STDERR.puts 'No archives found.'
  exit -1
end

candidates.sort! { |a, b|
  if a['CreationDate'] < b['CreationDate']
    1
  elsif a['CreationDate'] > b['CreationDate']
    -1
  elsif a['ArchiveVersion'] < b['ArchiveVersion']
    1
  elsif a['ArchiveVersion'] > b['ArchiveVersion']
    -1
  else
    0
  end
}

puts candidates[0][:archive_path]

