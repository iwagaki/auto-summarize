#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-

$LOAD_PATH.push(File.dirname(File.expand_path(__FILE__)) + '/..')
require 'cron_scraper'
require 'rss'

class TestCase < Scraper
  def initialize(uri)
    @uri = uri
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
    return page.items.first.pubDate
  end
  
  def scrape(page)
    news = ''
    page.items.each do |item|
      news << "<a href=\"#{item.link}\">#{item.title}</a><p>\n"
    end
    return news
  end
end

URIs = [
        # 'http://0xcc.net/blog/index.rdf'
       ]

URIs.each do |uri|
  runner = TestCase.new(uri)
  runner.run
end
