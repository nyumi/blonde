require 'open-uri'
require 'nokogiri'
require 'date'
require 'uri'

class WatchListsController < ApplicationController

  DOMAIN = "https://www.amazon.co.jp"
  # webページを表す
  class Page
    attr_reader :scraped_data, :url

    # scrape
    def initialize(url)
      @url = URI.encode(url)
      opt = {'User-Agent'=> 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_3) '+
          'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'}

      charset = nil
      html = open(@url,opt) do |f|
        charset = f.charset # 文字種別を取得
        f.read
      end
      @scraped_data = Nokogiri::HTML.parse(html, nil, charset)
    end
  end

  # Kindleページを表す
  class KindlePage < Page

    def initialize(page)
      @scraped_data = page.scraped_data
      @url = page.url
    end

    # 紙の本の情報に移動
    def turn_to_paper
      page = Page.new(DOMAIN + @scraped_data.at_css('.top-level.unselected-row .dp-title-col .title-text')['href'])
      PaperPage.new(page)
    end

    def set_content(book_id)
      KindleBook.new(
          book_id: book_id,
          published_date: publish_date,
          detail_link: @url

      )
    end

    def set_history(book_id)
      KindleHistory.new(
          book_id: book_id,
          price: price,
          point: point
      )
    end

    def price
      doc_price = @scraped_data.at_css('.a-color-price.a-size-medium.a-align-bottom')
      doc_price.children&.children&.remove
      text_price = doc_price.text
      text_price.gsub(/(\r\n|\r|\n|\s|￥|,)/, "").to_i
    end

    def point
      text_point = @scraped_data.at_css('.loyalty-points > .a-color-price.a-align-bottom').text
      trim_point = /pt/.match(text_point.gsub(/(\r\n|\r|\n|\s)/, ""))
      trim_point.pre_match.gsub(/,/,"").to_i
    end

    def publish_date
      text_pub_date = @scraped_data.at_css('.a-button-stack .a-section.a-text-center .a-size-mini > span > b')&.text
      Date.parse(text_pub_date) if text_pub_date
    end
  end

  # 紙の本を表す
  class PaperPage < Page
    def initialize(page)
      @scraped_data = page.scraped_data
      @url = page.url
    end

    def turn_to_kindle
      a_tag = @scraped_data.at_css(".a-button.a-spacing-mini.a-button-toggle.format > .a-button-inner > a")
      if a_tag
        page = Page.new(DOMAIN + a_tag['href'])
        KindlePage.new(page)
      end
    end

    def set_book_data(user_id,img)
      Book.new(
          title: title,
          author: author,
          user_id: user_id,
          publish_date: publish_date,
          img: img
      )
    end

    def set_content(book_id)
      PaperBook.new(
          book_id: book_id,
          detail_link: @url
      )
    end

    def set_history(book_id)
      PaperHistory.new(
          book_id: book_id,
          price: price,
          point: point
      )
    end

    def title
      @scraped_data.title.split("|").first
    end

    def author
      @scraped_data.title.split("|")[1]
    end

    def publish_date
      pub_date =  @scraped_data.css("#title > .a-size-medium.a-color-secondary.a-text-normal")[1].text # – 2016/12/31
      Date.parse(pub_date[2, pub_date.length-1])
    end

    def price
      text_price = @scraped_data.at_css('.a-size-medium.a-color-price.offer-price.a-text-normal').text
      text_price[2, text_price.length-1].to_i
    end

    def point
      text_point = @scraped_data.at_css('#buyBoxInner .a-color-price').text.gsub(/(\r\n|\r|\n|\s|￥)/, "")
      /pt/.match(text_point).pre_match.gsub(/,/,"").to_i
    end
  end

  # ユーザー毎のWatchList表示する。
  def index
    cuid = current_user.id

    list = WatchListView.where(user_id:cuid)
    book_ids = list.map {|book| book.id}


    kindle_histories = KindleHistory.where(book_id: book_ids).reduce({})  do |histories,history|
      b_history = histories[history.book_id]
      if b_history == nil
        b_history = {}
      end
      b_history.store(history.created_at.to_date.to_s, history.point)
      histories.store(history.book_id, b_history)
      histories
    end

    paper_histories = PaperHistory.where(book_id: book_ids).reduce({}) do |histories,history|
      b_history = histories[history.book_id]
      if b_history == nil
        b_history = {}
      end
      b_history.store(history.created_at.to_date.to_s, history.point)
      histories.store(history.book_id, b_history)
      histories
    end

    @watch_lists = list.map do |l|
      w = {}
      marged_date = kindle_histories[l.id].keys&paper_histories[l.id].keys
      w["list"] = l
      w["data"] = {
          labels:marged_date,
          datasets: [
            {
                label: "Paper Point",
                backgroundColor: "rgba(255,205,210,0.2)",
                borderColor: "rgba(255,205,210,1)",
                data: marged_date.map {|date|paper_histories[l.id][date]}
            },
            {
                label: "Kindle Point",
                backgroundColor: "rgba(225,190,231,0.2)",
                borderColor: "rgba(225,190,231,1)",
                data: marged_date.map {|date|kindle_histories[l.id][date]}
            }
          ]
        }
      w["options"] = {:height => 100}
      w
    end
  end

  def destroy
    book = Book.find_by(id:params[:id])
    book.destroy
    redirect_to root_path
  end

  def add
    page = Page.new(params[:link])
    img = params[:img]
    p_page = nil
    k_page = nil
    if kindle?(page.scraped_data)
      k_page = KindlePage.new(page)
      p_page = k_page.turn_to_paper
    else
      p_page = PaperPage.new(page)
      k_page = p_page.turn_to_kindle

    end


    book = p_page.set_book_data(current_user.id,img)
    book.save

    p_page.set_content(book.id).save
    p_page.set_history(book.id).save


    if k_page != nil
      k_page.set_content(book.id).save
      k_page.set_history(book.id).save
    end

    redirect_to root_path
  end

  # Kindleかどうか判定する
  # @param [Nokogiri] doc 判定対象のNokogiriオブジェクト
  # @return [boolean] Kindleかどうか
   def kindle?(doc)
    doc.at_css('#productDetailsTable .content li')&.text&.include?("Kindle")
  end

  def search
    @keywords = params[:keywd]
    key = URI.escape(@keywords)
    url = DOMAIN +
          '/s/ref=nb_sb_noss' +
          '?__mk_ja_JP=%E3%82%AB%E3%82%BF%E3%82%AB%E3%83%8A&url=search-alias%3Dstripbooks&field-keywords=' +
          key

    doc = scrape(url)
    @searched_books = []
    doc.css('.s-result-item.celwidget').each do |book|
      s_book = {title: book.at_css('.a-link-normal.s-access-detail-page.a-text-normal')['title'],
                link: book.at_css('.a-link-normal.a-text-normal')['href'],
                img: retreve_image(book)}
      @searched_books.push(s_book)
    end
  end

  # 受け取ったNokogiriオブジェクト内からimgを取得して返す
  # @param [Nokogiri] doc imgをスクレイプする対象のNokogiriオブジェクト
  # @return [String] スクレイプ結果のimgリンク
  def retreve_image(doc)
    doc.at_css('.a-link-normal.a-text-normal > img')['src']
  end

  # 受け取ったURLで返ってくるHTMLをスクレイピングする
  # @param [String] url スクレイプ対象のURL　
  # @return [Nokogiri] スクレイプ結果のNokogiriオブジェクト
  def scrape(url)
    opt = {}
    opt['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_3) '+
                          'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'

    charset = nil
    html = open(url,opt) do |f|
      charset = f.charset # 文字種別を取得
      f.read
    end
    # htmlをパース(解析)してオブジェクトを生成
    Nokogiri::HTML.parse(html, nil, charset)
  end


  # 受け取ったNokogiriオブジェクトから本の情報をBookテーブルに保存する
  # @param [Nokogiri] scraped_data Bookテーブルに必要なデータが入っているNokogiriオブジェクト　
  # @return [Book] 保存されたBookオブジェクト
  def save_book(scraped_data, img)
    # 作者とタイトル等の情報
    book_data = scraped_data.title.split("|")
    pub_date =  scraped_data.css("#title > .a-size-medium.a-color-secondary.a-text-normal")[1].text # – 2016/12/31

    title = book_data.first
    author = book_data[1]

    book = Book.new(title: title,
                    author: author,
                    user_id: current_user.id,
                    publish_date: Date.parse(pub_date[2, pub_date.length-1]),
                    img: img)
    book.save
    book
  end

  # 受け取ったNokogiriオブジェクトから紙の本の情報をPaperBookテーブルに保存する
  # @param [Nokogiri] scraped_data PaperBookテーブルに必要なデータが入っているNokogiriオブジェクト　
  # @param [Book] book 紐づくBookオブジェクト
  # @param [String] url 紙本の詳細リンク
  def save_paper_book(scraped_data, book, url)
    # 紙本価格
    html_price  = scraped_data.at_css('.a-size-medium.a-color-price.offer-price.a-text-normal').text.gsub(/,/,"")
    price =  html_price[2, html_price.length-1].to_i

    # 紙本ポイント
    html_point = scraped_data.at_css('#buyBoxInner .a-color-price').text.gsub(/(\r\n|\r|\n|\s|￥|,)/, "")
    point =  /pt/.match(html_point).pre_match.gsub(/,/,"").to_i

    pp_book = PaperBook.new(book_id: book.id, detail_link: url)
    pp_book.save
    history = PaperHistory.new(price: price, point: point, book_id: book.id)
    history.save
  end

  # 受け取ったNokogiriオブジェクトから紙の本の情報をKindleBookテーブルに保存する
  # @param [Nokogiri] scraped_data KindleBookテーブルに必要なデータが入っているNokogiriオブジェクト　
  # @param [Book] book 紐づくBookオブジェクト
  # @param [String] url Kindle本の詳細リンク
  def save_kindle_book(scraped_data, book, url)
    # Kindle価格を取得
    noko_price = scraped_data.at_css('.a-color-price.a-size-medium.a-align-bottom')
    noko_price.children&.children&.remove
    html_price = noko_price.text.gsub(/,/,"")
    # Kindleのpoint値取得
    html_point = scraped_data.at_css('.loyalty-points > .a-color-price.a-align-bottom').text
    # 改行とか消す
    price =  html_price.gsub(/(\r\n|\r|\n|\s|￥)/, "").to_i
    # 改行とか消した後に、ptより前の文字取得してピリオドを取る
    point = /pt/.match(html_point.gsub(/(\r\n|\r|\n|\s)/, ""))
    kin_point = point.pre_match.gsub(/,/,"").to_i
    k_pub_date = scraped_data.at_css('.a-button-stack .a-section.a-text-center .a-size-mini > span > b')&.text
    future_pub_date = Date.parse(k_pub_date) if k_pub_date

    kbook = KindleBook.new(book_id: book.id, published_date: future_pub_date, detail_link: url)
    kbook.save
    history = KindleHistory.new(book_id: book.id, price: price, point: kin_point)
    history.save
  end
end

