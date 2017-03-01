# URLにアクセスするためのライブラリの読み込み
require 'open-uri'
# Nokogiriライブラリの読み込み
require 'nokogiri'
require 'date'
require 'uri'
class WatchListsController < ApplicationController
  def index
    @watch_lists = WatchListView.all
  end

  def add

    opt = {}
    opt['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'

# スクレイピング先のURL
# ワンピ紙最新刊
#     url = 'https://www.amazon.co.jp/ONE-PIECE-84-%E3%82%B8%E3%83%A3%E3%83%B3%E3%83%97%E3%82%B3%E3%83%9F%E3%83%83%E3%82%AF%E3%82%B9-%E6%A0%84%E4%B8%80%E9%83%8E/dp/4088810023/ref=sr_1_1?s=books&ie=UTF8&qid=1488099214&sr=1-1&keywords=%E3%83%AF%E3%83%B3%E3%83%94%E3%83%BC%E3%82%B9
# '

    # url = 'https://www.amazon.co.jp/s/ref=nb_sb_noss?__mk_ja_JP=%E3%82%AB%E3%82%BF%E3%82%AB%E3%83%8A&url=search-alias%3Dstripbooks&field-keywords=%E9%8A%80%E9%AD%82&rh=n%3A465392%2Ck%3A%E9%8A%80%E9%AD%82'
    url = 'https://www.amazon.co.jp/s/ref=nb_sb_noss?__mk_ja_JP=カタカナ&url=search-alias%3Dstripbooks&field-keywords=銀魂&rh=n%3A465392%2Ck%3A銀魂'
    charset = nil
    html = open(url,opt) do |f|
      charset = f.charset # 文字種別を取得
      f.read # htmlを読み込んで変数htmlに渡す
    end

# htmlをパース(解析)してオブジェクトを生成
    doc = Nokogiri::HTML.parse(html, nil, charset)

# 作者とタイトル等の情報
    book_data = doc.title.split("|")
    title = book_data.first
    author = book_data[1]
    pub = doc.css('.a-size-medium.a-color-secondary.a-text-normal')[1].children.text

    book = Book.new(title: title, author: author, user_id: current_user.id, publish_date: Date.parse(pub[2, pub.length-1]) )
    book.save

# 紙本価格
    p_price  = doc.at_css('.a-size-medium.a-color-price.offer-price.a-text-normal').children.text
    papre_price =  p_price[2, p_price.length-1].to_i

# 紙本ポイント
    p_point = doc.at_css('#buyBoxInner .a-color-price').text.gsub(/(\r\n|\r|\n|\s|￥)/, "")
    paper_point =  /pt/.match(p_point).pre_match.gsub(/,/,"").to_i

    pp_book = PaperBook.new(price: papre_price, point: paper_point, book_id: book.id)
    pp_book.save


# ワンピKindle最新刊
    kurl = 'https://www.amazon.co.jp/ONE-PIECE-%E3%83%A2%E3%83%8E%E3%82%AF%E3%83%AD%E7%89%88-84-%E3%82%B8%E3%83%A3%E3%83%B3%E3%83%97%E3%82%B3%E3%83%9F%E3%83%83%E3%82%AF%E3%82%B9DIGITAL-ebook/dp/B01N6IG5MU/ref=la_B0034OTZEG_1_1_twi_kin_2?s=books&ie=UTF8&qid=1488090375&sr=1-1'
    charset = nil
    html = open(kurl,opt) do |f|
      charset = f.charset # 文字種別を取得
      f.read # htmlを読み込んで変数htmlに渡す
    end


# htmlをパース(解析)してオブジェクトを生成
    kdoc = Nokogiri::HTML.parse(html, nil, charset)
# Kindle価格を取得
    k_price = kdoc.at_css('.kindle-price').children.css('.a-color-price.a-size-medium.a-align-bottom').text
# Kindleのpoint値取得
    k_point = kdoc.at_css('.loyalty-points').children.css('.a-color-price.a-align-bottom').text
# 改行とか消す
    kin_price =  k_price.gsub(/(\r\n|\r|\n|\s|￥)/, "").to_i
# 改行とか消した後に、ptより前の文字取得してピリオドを取る
    point = /pt/.match(k_point.gsub(/(\r\n|\r|\n|\s)/, ""))
    kin_point = point.pre_match.gsub(/,/,"").to_i
    k_pub_date =  kdoc.at_css('.a-button-stack .a-section.a-text-center > span').child.next_sibling.child.text
    future_pub_date = Date.parse(k_pub_date)

    kbook = KindleBook.new(book_id: book.id, price: kin_price, published_date: future_pub_date, point: kin_point )
    kbook.save
    render json: {book: book, pp_book: pp_book, kin_book: kbook}

  end

  def search
    key = URI.escape(params[:keywd])
    url = 'https://www.amazon.co.jp/s/ref=nb_sb_noss?__mk_ja_JP=%E3%82%AB%E3%82%BF%E3%82%AB%E3%83%8A&url=search-alias%3Dstripbooks&field-keywords=' + key
    # url = 'https://www.amazon.co.jp/s/ref=nb_sb_noss_2?__mk_ja_JP=%E3%82%AB%E3%82%BF%E3%82%AB%E3%83%8A&url=search-alias%3Dstripbooks&field-keywords=' + key + '&rh=n%3A465392%2Ck%3A' +  key
    p

    opt = {}
    opt['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'

    charset = nil
    html = open(url,opt) do |f|
      charset = f.charset # 文字種別を取得
      f.read # htmlを読み込んで変数htmlに渡す
    end

# htmlをパース(解析)してオブジェクトを生成
    doc = Nokogiri::HTML.parse(html, nil, charset)
    @searched_books = []
    doc.css('.a-link-normal.s-access-detail-page.a-text-normal').each do |book|
      # s_book = {}
      s_book = {title:book['title'], link: book['href']}
      @searched_books.push(s_book)
    end

    @searched_books
  end
end
