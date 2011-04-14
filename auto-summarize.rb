#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-
#
# Copyright (c) 2010 iwagaki@users.sourceforge.net
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Environment Variables:
#   GMAIL_USERNAME
#   GMAIL_PASSWORD
#   GMAIL_ADDRESS

require 'rubygems'
require 'mechanize'
require 'cgi'
require 'kconv'
require 'yaml'
require 'hpricot'
require 'nkf'
if $DEBUG
require 'ruby-debug'
require 'ruby-prof'
require 'pp'
end
require 'gmail'

class Mechanize
  class Form
    class Field
      def <=> other
        return 0 if self == other
        return 1 if Hash === node
        return -1 if Hash === other.node

        pp node.class
        pp other.node.class
        pp node
        pp other.node
        result = node <=> other.node
        puts result
        puts '--------------'
        return result
        # if node['name'] == other.node['name'] && node['value'] == other.node['value']
        #   puts 'OK'
        #   puts '--------------'
        #   return 0
        # end
        # puts 'NG'
        #   puts '--------------'
        # return -1
      end
    end
  end
end

class Link
  def initialize
    @title = nil
    @url = nil
    @description = nil
    @category = nil
    @rank = 0
  end
  attr_accessor :title, :url, :description, :category, :rank
end

class Period
  def initialize
    @start = nil
    @update = nil
    @end = nil
  end
  attr_accessor :start, :update, :end
end

class AutoSummarize
public
  def get_file
    return $0
  end

  def get_name
    return 'Undefined'
  end

  def is_html?
    return true
  end

  def get_page(url)
    return @agent.get(url)
  end

  def get_yaml_base
    return get_file.gsub(/\.rb/, '')
  end
  
  def tear_up
    raise
  end

  def get_links(page)
    raise
  end

  def get_categories
    return [nil]
  end

  def get_freq
    # [wday [0:Sun - 6:Sat], hour, min]
    return [0, 0, 0]
  end

  def get_max_num_of_links
    return 10
  end

  def scrape(page)
    raise
  end

  def tear_down(page)
  end

  def time_to_s(time)
    return time.strftime('%Y-%m-%d %H:%M')
  end

  def run
    # Nokogiri-1.4.2
    Mechanize.html_parser = Hpricot
    @agent = Mechanize.new
    @agent.post_connect_hooks << lambda {|params|
      params[:response_body] = Kconv.kconv(params[:response_body], Kconv::UTF8)
    }

    if __FILE__ == $0
      page = get_page('http://www.jiji.com/jc/r')
      pp page
      exit
    end

    @news_array = Array.new
    mail = ''

    @scheduled_time = YAML.load_file(get_yaml_base + '.sched_time.yaml') rescue Period.new
    @links_hash = YAML.load_file(get_yaml_base + '.links_hash.yaml') rescue Hash.new

    @page = tear_up
    update_time = check_update(@page)

    puts "web update: #{update_time}"
    puts "last update: #{@scheduled_time.update}"

    if ($DEBUG || @scheduled_time.update == nil || update_time > @scheduled_time.update)
      @new_links = get_links(@page)

      for link in @new_links
        if @links_hash.has_key?(link.url)
          old_rank = @links_hash[link.url].rank
          link.rank += old_rank
        end
        @links_hash[link.url] = link
      end

      @scheduled_time.update = update_time
    end

    now = Time.now
    if @scheduled_time.end == nil or now > @scheduled_time.end
      ranked_links = @links_hash.to_a.sort{|a, b|
        b[1].rank <=> a[1].rank
      }

      categories = get_categories

      for category in categories
        if category != nil
          mail << "<b>#{category}</b><br><br>\n"
        end
        
        count = 0
        for link in ranked_links
          # link[0] = key
          # link[1] = value

          if count >= get_max_num_of_links
            break
          end

          if category == nil || link[1].category == category
            mail << "<a href=\"#{link[1].url}\">#{link[1].title}</a> (#{link[1].rank} pts)<br>\n"
            if link[1].description != nil
              mail << "#{link[1].description}<br>\n"
            end
            mail << "<br>\n"
            count += 1
          end
        end

        mail << "<br><br>\n"
      end

      if mail != ""
        html_mail = "<html>\n"
        html_mail << "<head>\n"
        html_mail << "</head>\n"
        html_mail << "<body>\n"

        html_mail << mail
        html_mail << "</body>\n"
        html_mail << "</html>\n"

        period_start = @scheduled_time.start != nil ? time_to_s(@scheduled_time.start) : '???'
        period_end = @scheduled_time.end != nil ? time_to_s(@scheduled_time.end) : '???'
        
        gmail = Gmail.new(ENV['GMAIL_USERNAME'], ENV['GMAIL_PASSWORD'], ENV['GMAIL_ADDRESS'])
        gmail.subject = "auto-summarize #{get_name} <#{period_start} ~ #{period_end}>"
        gmail.message = NKF.nkf('-WIj --cp932', html_mail)
        gmail.send_html(ENV['GMAIL_ADDRESS'])
      end

      sched_day = now.day
      candidate = Time.local(now.year, now.month, now.day, get_freq[1], get_freq[2], 0)
      if now.wday == get_freq[0]
        if candidate < now
          candidate += 7*24*60*60
        end
      elsif now.wday < get_freq[0]
        candidate += (get_freq[0] - now.wday)*24*60*60
      else
        candidate += (7 - (now.wday - get_freq[0]))*24*60*60
      end
      @scheduled_time.end = candidate
      @scheduled_time.start = update_time
      @links_hash.clear
    end

    puts "start: #{@scheduled_time.start}"
    puts "end: #{@scheduled_time.end}"

    if !$DEBUG
      if @scheduled_time != nil
        YAML.dump(@scheduled_time, File.open(get_yaml_base + '.sched_time.yaml', 'w'))
      end
      YAML.dump(@links_hash, File.open(get_yaml_base + '.links_hash.yaml', 'w'))
    end

    tear_down(@page)
  end
end

# set_trace_func lambda { |event, file, line ,id, binding, classname|
#   if event == 'call' && id == :get_page
#     puts "#{file}:#{line} entering method #{id}"
#   end
# }

if __FILE__ == $0
  test = AutoSummarize.new
  test.run
end
