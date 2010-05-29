#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-

$LOAD_PATH.push(File.dirname(File.expand_path(__FILE__)) + '/..')
require 'cron_scraper'

require 'pp' if $DEBUG

# isDebug = $VERBOSE
# $VERBOSE = nil
# $VERBOSE = isDebug

# name      twitter ネーム
# content   本文
# has_url   URLを含んでいるステータス
# has_reply @自分のステータス
# length    ステータスの長さ

def filter(name, content, has_url, has_reply, length)
  # 自分は通さない
  return false if name == ENV['TWITTER_USERNAME']

  # 自分宛のステータスは通す
  return true if has_reply

  # 特定キーワードは通さない
  return false if content =~ /From my iPhone/
  return false if content =~ /I'm at /
 
  # URL を含むステータスは通す
  return true if has_url

  # # 短すぎるステータスは通さない
  # return false if length < 15

  # 特定の人は通さない
  # return false if name == 'xxxxx'

  return false
end


class TestCase < Scraper
  MAX_PAGES = 30

  def get_name
    return 'Twitter'
  end

  def tear_up
    page = @agent.get('http://twitter.com/login')
    form = page.forms[1]
    form['session[username_or_email]'] = ENV['TWITTER_USERNAME']
    form['session[password]'] = ENV['TWITTER_PASSWORD']
    page = @agent.submit(form, form.buttons.first)
    return page
  end

  def check_update(page)
    @entry_parser = EntryParser.new
    page_parser = PageParser.new(@entry_parser)

    for i in 1..MAX_PAGES
      puts "scraping ... Page #{i}\n"
      page = get_page("http://twitter.com/timeline/home?page=#{i}")
      break unless page_parser.parse(page, @last_update_time)
    end

    p @entry_parser.latest_status
    return @entry_parser.latest_status.to_i
  end

  def time_to_s(time)
    return time
  end

  def scrape(page)
    return @entry_parser.mail
  end

  class EntryParser
    attr_reader :mail
    attr_reader :latest_status

    def initialize()
      @latest_status = nil
      @mail = ''
    end

    def parse(entry, last_update_time)
      name = entry.search('a').first.inner_text
      raise if name == nil
      meta = entry.search('a[@class="entry-date"]').first
      raise "Cannot find a search word" if meta == nil
      time = meta.search('span.published').first.inner_text
      status = meta['href'].gsub(%r{http://twitter.com/[^/]+/status/([0-9]+)}m, '\1')
      pp status if $DEBUG

      if name == '' || time == '' || status == ''
        puts '** ERROR ** incorrect account or passowrd, otherwise twitter.com might be updated'
        return false
      end
      
      # 最新のステータスの URL を保存
      @latest_status ||= status
      
      # 前回処理済み
      return false if last_update_time != nil && status.to_i <= last_update_time

      content = CGI.unescapeHTML(entry.search('span.entry-content').first.inner_html).gsub(/^\s+/, '')

      pp content if $DEBUG
      
      # リンクは ... で省略されるので URL に置き換える
      # %r{...} 記法だが [^"] だと emacs の ruby-mode で正しく表示されないため [^\"] としている
      content = content.gsub(%r{<a\s+href="([^\"]*)"\s+class="tweet-url\s+web"\s+rel="[^\"]*"[^>]*>.*?</a>}m, '\1')
      url = $1
      has_url = (url != nil)
      
      # 文字オーバーのリンクは削除する
      content = content.gsub(%r{<a\s+href="[^\"]*"[^>]*>\.+</a>}m, '')
      length = content.split(//).size
      
      # @username のリンクを解除する
      has_reply = false
      content = content.gsub(%r{<a\s+class="tweet-url\s+username"\s+href="[^\"]*"[^>]*>(.*?)</a>}m) { |replyname| 
        username = $1
        if username == ENV['TWITTER_USERNAME']
          has_reply = true # @自分の場合はフラグを立てる
        end
        $1
      }
      # hashtag 他のリンクは解除する
      content = content.gsub(%r{<a\s+href="[^\"]*"[^>]*>(.*?)</a>}m, '\1')

      pp has_url, has_reply, length, content if $DEBUG
      
      # 時系列（逆順）に追加する
      if filter(name, content, has_url, has_reply, length)
        stat =  "-----------------------------------------<br>\n"
        stat << "<b>#{name}</b><br><br>\n"
        stat << "#{content}<br>\n"
        stat << "#{time}<br>\n"
        @mail = stat + @mail
      end
      
      return true
    end
  end

  class PageParser
    def initialize(entry_parser)
      @entry_parser = entry_parser
    end

    def parse(page, last_update_time)
      page.search('span.status-body').each do |entry|
        return false unless @entry_parser.parse(entry, last_update_time)
      end
      return true
    end
  end
end

runner = TestCase.new
runner.run
