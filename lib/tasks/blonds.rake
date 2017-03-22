namespace :blonds do
  desc "Daily scrape job for book data "
  task :generate => :environment do
    # paper
    paper_books = PaperBook.all

    paper_books.each do |book|
      paper_data = scrape(book.detail_link)
      # 紙本価格
      html_price  = paper_data.at_css('.a-size-medium.a-color-price.offer-price.a-text-normal').text
      price =  html_price[2, html_price.length-1].to_i

      # 紙本ポイント
      html_point = paper_data.at_css('#buyBoxInner .a-color-price').text.gsub(/(\r\n|\r|\n|\s|￥)/, "")
      point =  /pt/.match(html_point).pre_match.gsub(/,/,"").to_i

      history = PaperHistory.new(book_id:book.book_id, price:price, point:point)
      history.save!

    end
    # kindle

    kindle_books = KindleBook.all

    kindle_books.each do |kin_book|
      kindle_data = scrape(kin_book.detail_link)

      # Kindle価格を取得
      kin_data = kindle_data.at_css('.a-color-price.a-size-medium.a-align-bottom')
      kin_data.children&.children&.remove
      html_price = kin_data.text
      # Kindleのpoint値取得
      html_point = kindle_data.at_css('.loyalty-points > .a-color-price.a-align-bottom').text
      # 改行とか消す
      kin_price =  html_price.gsub(/(\r\n|\r|\n|\s|￥)/, "").to_i
      # 改行とか消した後に、ptより前の文字取得してピリオドを取る
      point = /pt/.match(html_point.gsub(/(\r\n|\r|\n|\s)/, ""))
      kin_point = point.pre_match.gsub(/,/,"").to_i

      history = KindleHistory.new(book_id:kin_book.book_id, price: kin_price, point: kin_point)
      history.save!
    end
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
end
