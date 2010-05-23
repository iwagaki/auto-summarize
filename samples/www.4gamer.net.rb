#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-

$LOAD_PATH.push(File.dirname(File.expand_path(__FILE__)) + '/..')
require 'cron_scraper'

class TestCase < ScraperBase
  def initialize
    @mail = ''
  end

  def get_file
    return __FILE__
  end

  def get_name
    return '4gamer'
  end

  def is_html?
    return true
  end

  def tear_up
    return get_page('http://www.4gamer.net/')
  end

  def check_update(page)
    this_update = nil

    page.search('div').each do |entry|
      if entry['class'] == "container"
        url = 'http://www.4gamer.net' + entry.search('a').first['href']
        title = entry.search('a').inner_text.gsub(/^\s+/, '')
        @mail << "<a href=\"#{url}\">#{url}</a><br>\n"
        @mail << "#{title}<br><br>\n"
      elsif entry['class'].to_s == 'period'
        this_update = entry.inner_text
        break
      end
    end

    year = Time.now.year
    if /集計：\d+月\d+日〜(\d+)月(\d+)日/ =~ this_update
      month = $1
      day = $2
    end
    
    return Time.local(year, month, day)
  end

  def scrape(page)
    return @mail
  end

  def tear_down(page)
  end

end

runner = TestCase.new
runner.run
