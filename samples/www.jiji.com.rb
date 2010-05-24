#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-

$LOAD_PATH.push(File.dirname(File.expand_path(__FILE__)) + '/..')
require 'cron_scraper'

class TestCase < Scraper
  MAX_NUM_OF_ARTICLES = 20

  def get_name
    return 'Jiji'
  end

  def tear_up
    return get_page('http://www.jiji.com/rss/ranking.rdf')
  end

  def check_update(page)
    if page.body =~ /^<dc:date>(.*)<\/dc:date>/
      return Time.parse($+)
    end
    puts "Error: failed to get updated timestamp"
    exit
  end
  
  def scrape(page)
    page = get_page('http://www.jiji.com/jc/r')
    base_url = 'http://www.jiji.com/jc/'
    
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
            if count > MAX_NUM_OF_ARTICLES
              break
            end
            count += 1
            url = base_url + entry['href']

            linked_page = get_page(url)
            title = linked_page.search('title').first.inner_text.sub(/時事ドットコム：/, "")
            news << "<a href=\"#{url}\">#{title}</a><p>\n"
          end
        end
      end
    end

    return news
  end
end

runner = TestCase.new
runner.run
