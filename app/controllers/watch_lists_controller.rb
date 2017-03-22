require 'open-uri'
require 'nokogiri'
require 'date'
require 'uri'

class WatchListsController < ApplicationController

  DOMAIN = "https://www.amazon.co.jp"

  def index
    tmp = WatchListView.where(user_id:current_user.id)
    @watch_lists = []
    tmp.each do |l|
      w = {}
      w["list"] = l
      w["data"] = {
          labels: [
            Date.today, Date.today+1, Date.today+2, Date.today+3, Date.today+4, Date.today+5, Date.today+6,
            Date.today+7, Date.today+8, Date.today+9, Date.today+10, Date.today+11, Date.today+12, Date.today+13
          ],
          datasets: [
            {
                label: "Paper Point",
                backgroundColor: "rgba(255,205,210,0.2)",
                borderColor: "rgba(255,205,210,1)",
                data: [
                  650, 590, 800, 810, 560, 550, 400,
                  650, 590, 800, 810, 560, 550, 400
                ]
            },
            {
                label: "Kindle Point",
                backgroundColor: "rgba(225,190,231,0.2)",
                borderColor: "rgba(225,190,231,1)",
                data: [
                  280, 480, 400, 190, 860, 270, 900,
                  280, 480, 400, 190, 860, 270, 900
                ]
            }
          ]
        }
      w["options"] = {:height => 100}
      @watch_lists.push(w)
    end
  end

  def destroy
    book = Book.find_by(id:params[:id])
    book.destroy
    redirect_to root_path
  end

  def add
    doc = scrape(params[:link])
    img = params[:img]

    if kindle?(doc)
      # 紙本のリンク取得
      pp_url =  URI.encode(DOMAIN + doc.at_css('.top-level.unselected-row .dp-title-col .title-text')['href'])
      ppdoc = scrape(pp_url)
      # コミック情報登録
      book = save_book(ppdoc,img)
      save_paper_book(ppdoc, book,pp_url)

      # Kindle情報登録
      save_kindle_book(doc, book, params[:link])

    else #文庫には対応しない
      # コミック情報登録
      book = save_book(doc,img)
      save_paper_book(doc, book, params[:link])

      # Kindleリンク探しに行く
      noko_link = doc.at_css(".a-button.a-spacing-mini.a-button-toggle.format > .a-button-inner > a")
      if noko_link
        kindle_link = URI.escape(DOMAIN + noko_link['href'])
        save_kindle_book(scrape(kindle_link),book, kindle_link)
      end
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
    html_price  = scraped_data.at_css('.a-size-medium.a-color-price.offer-price.a-text-normal').text
    price =  html_price[2, html_price.length-1].to_i

    # 紙本ポイント
    html_point = scraped_data.at_css('#buyBoxInner .a-color-price').text.gsub(/(\r\n|\r|\n|\s|￥)/, "")
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
    html_price = noko_price.text
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

