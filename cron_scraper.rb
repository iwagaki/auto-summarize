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
# 環境変数
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


Mechanize.html_parser = Hpricot
$agent = Mechanize.new
$agent.post_connect_hooks << lambda {|params| params[:response_body] = Kconv.kconv(params[:response_body], Kconv::UTF8)}

$news_array = Array.new

def getNews(page, base_url, max)
# prof = RubyProf.profile do
  news = ""
  flag = false
  
#  vlist = {"rnk"=>"総合", "rnk_soc"=>"社会", "rnk_pol"=>"政治", "rnk_eco"=>"経済", "rnk_spo"=>"スポーツ", "rnk_int"=>"国際", "rnk_ind"=>"企業", "rnk_afp"=>"ワールドEYE", "rnk_ent"=>"エンタメ"}
  vlist = {"rnk_soc"=>"社会", "rnk_pol"=>"政治", "rnk_eco"=>"経済", "rnk_int"=>"国際", "rnk_ind"=>"企業", "rnk_afp"=>"ワールドEYE", "rnk_ent"=>"エンタメ"}

  page.search('div.ranking-box').each do |box|
    count = 1
    rnk_name = box.search('a').first['name']
    if vlist.key?(rnk_name)
      news << "<h3>#{vlist[rnk_name]}</h3>"
      box.search('a').each do |entry|
        if entry['name'] == nil
          if count > max
            break
          end
          count += 1
          url = base_url + entry['href']

          linked_page = getPage(url)
          title = linked_page.search('title').first.inner_text.sub(/時事ドットコム：/, "")
          news << "<a href=\"#{url}\">#{title}</a><p>\n"
        end
      end
    end
  end
# end
# printer = RubyProf::FlatPrinter.new(prof)
# printer.print(STDOUT, 0)

  return news
end

def getPage(url)
  return $agent.get(url)
end

def checkUpdate(page)
  if page.body =~ /^<dc:date>(.*)<\/dc:date>/
    return $+
  end
  exit
end

mail = ""

$last_update_time = YAML.load_file('status.yaml') rescue nil

page = getPage('http://www.jiji.com/rss/ranking.rdf')
update_time = Time.parse(checkUpdate(page))

page = getPage('http://www.jiji.com/jc/r')

if ($DEBUG || $last_update_time == nil || update_time > $last_update_time)
  if !$DEBUG
    YAML.dump(update_time, File.open('status.yaml', 'w'))
  end
  mail << "<html>\n"
  mail << "<head>\n"
  mail << "</head>\n"
  mail << "<body>\n"
  mail << getNews(page, 'http://www.jiji.com/jc/', 20)
  mail << "</body>\n"
  mail << "</html>\n"
end

plugin_name = "jiji_tsushin"

if mail != ""
  gmail = Gmail.new(ENV['GMAIL_USERNAME'], ENV['GMAIL_PASSWORD'], ENV['GMAIL_ADDRESS'])
  gmail.subject = "cron_scraper.rb #{plugin_name} #{update_time}"
  gmail.message = mail.tojis
  gmail.send_html(ENV['GMAIL_ADDRESS'])
end
