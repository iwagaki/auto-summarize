#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-

$LOAD_PATH.push(File.dirname(File.expand_path(__FILE__)) + '/..')
require 'auto-summarize'

class TestCase < AutoSummarize
  def get_name
    return '4gamer'
  end

  def tear_up
    return get_page('http://www.4gamer.net/')
  end

  def check_update(page)
    @links = Array.new
    this_update = nil
    weight = 0;

    page.search('div').each do |entry|
      if entry['class'] == "container"
        url = 'http://www.4gamer.net' + entry.search('a').first['href']
        title = entry.search('a').inner_text.gsub(/^\s+/, '')

        link = Link.new
        link.title = url
        link.url = url
        link.description = title
        link.rank = 10 - weight
        link.category = nil

        @links.push(link)
        weight += 1
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

  def get_links(page)
    return @links
  end

  def get_freq
    return [0, 0, 0]
  end

  def get_max_num_of_links
    return 10
  end
end

runner = TestCase.new
runner.run
