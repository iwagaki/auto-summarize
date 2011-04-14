#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-

$LOAD_PATH.push(File.dirname(File.expand_path(__FILE__)) + '/..')
require 'auto-summarize'

class TestCase < AutoSummarize
  MAX_NUM_OF_ARTICLES = 10

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
  
  def get_links(page)
    links = Array.new

    page = get_page('http://www.jiji.com/jc/r')
    base_url = 'http://www.jiji.com/jc/'
    
    news = ""
    flag = false
  
    #  vlist = {"rnk"=>"総合", "rnk_soc"=>"社会", "rnk_pol"=>"政治", "rnk_eco"=>"経済", "rnk_spo"=>"スポーツ", "rnk_int"=>"国際", "rnk_ind"=>"企業", "rnk_afp"=>"ワールドEYE", "rnk_ent"=>"エンタメ"}
    vlist = {"rnk_soc"=>"社会", "rnk_pol"=>"政治", "rnk_eco"=>"経済", "rnk_int"=>"国際", "rnk_ind"=>"企業", "rnk_afp"=>"ワールドEYE", "rnk_ent"=>"エンタメ"}

    page.search('div.ranking-box').each do |box|
      count = 0
      rnk_name = box.search('a').first['name']
      if vlist.key?(rnk_name)
        news << "<h3>#{vlist[rnk_name]}</h3>"
        box.search('a').each do |entry|
          if entry['name'] == nil
            if count >= MAX_NUM_OF_ARTICLES
              break
            end
            url = base_url + entry['href']

            linked_page = get_page(url)
            title = linked_page.search('title').first.inner_text.sub(/時事ドットコム：/, "")
            if title != '時事ドットコム'
              link = Link.new
              link.title = title
              link.url = url
              link.description = nil
              link.rank = MAX_NUM_OF_ARTICLES - count
              link.category = vlist[rnk_name]
              p link
              links.push(link)
            end
            count += 1
          end
        end
      end
    end
    return links
  end

  def get_freq
    return [0, 0, 0]
  end

  def get_max_num_of_links
    return 10
  end

  def get_categories
    return ["社会", "政治", "経済", "国際", "企業", "ワールドEYE", "エンタメ"]
  end
end

runner = TestCase.new
runner.run
