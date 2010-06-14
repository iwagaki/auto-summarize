#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-

$LOAD_PATH.push(File.dirname(File.expand_path(__FILE__)) + '/..')
require 'cron_scraper'
require 'rss'

require 'rss_uri'
# URIs = {
#   'uri1' => 'http://0xcc.net/blog/index.rdf',
#   'uri2' => 'http://feeds.feedburner.com/japantimes_news',
# }

class TestCase < Scraper
  def initialize(uri, yaml_name)
    @uri = uri
    @yaml_name = yaml_name
  end

  def get_file
    return @yaml_name
  end

  def get_name
    return 'RSS'
  end

  def tear_up
    rss = open(@uri) { |file|
      RSS::Parser.parse(file.read)
    }
    return rss
  end

  def check_update(page)
    if page.items.first.date == nil
      return Time.now
    else
      return page.items.first.date
    end
  end
  
  def scrape(page)
    news = ''
    page.items.each do |item|
      news << "<a href=\"#{item.link}\">#{item.title}</a><p>\n"
    end
    return news
  end
end

URIs.each do |key, uri|
  runner = TestCase.new(uri, $0 + '-' + key)
  runner.run
end
