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
if $DEBUG
require 'ruby-debug'
require 'ruby-prof'
require 'pp'
end
require 'gmail'

# class Mechanize
#   class Form
#     class Field
#       def <=> other
#         return 0 if self == other
#         return 1 if Hash === node
#         return -1 if Hash === other.node
#         return nil
#       end
#     end
#   end
# end

class Scraper
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

  def get_yaml_file
    return get_file.gsub(/\.rb/, '') + '.yaml'
  end
  
  def tear_up
    raise
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
#    Mechanize.html_parser = Hpricot
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

    @last_update_time = YAML.load_file(get_yaml_file) rescue nil

    @page = tear_up
    update_time = check_update(@page)

    if ($DEBUG || @last_update_time == nil || update_time > @last_update_time)
      if !$DEBUG
        YAML.dump(update_time, File.open(get_yaml_file, 'w'))
      end
      mail << "<html>\n"
      mail << "<head>\n"
      mail << "</head>\n"
      mail << "<body>\n"
      mail << scrape(@page)
      mail << "</body>\n"
      mail << "</html>\n"
    end
    
    if mail != ""
      gmail = Gmail.new(ENV['GMAIL_USERNAME'], ENV['GMAIL_PASSWORD'], ENV['GMAIL_ADDRESS'])
      gmail.subject = "cron_scraper #{get_name} #{time_to_s(update_time)}"
      gmail.message = mail.tojis
      gmail.send_html(ENV['GMAIL_ADDRESS'])
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
  test = Scraper.new
  test.run
end
