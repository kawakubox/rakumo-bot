class Board
  attr_accessor :name, :title, :url, :created_at, :updated_at
  def self.parse element
    board = Board.new
    board.name = element.css('div:nth-of-type(2) span.boardName').text
    board.title = element.css('div.postTitle a').text
    board.url = 'https://a-rakumo.appspot.com/board' + element.css('div.postTitle a').attr('href').value
    matches = element.css('div.contentUpdated').text.match(/(\d{4}).(\d{1,2}).(\d{1,2})/)
    board.updated_at = Date.new(matches[1].to_i, matches[2].to_i, matches[3].to_i) if matches
    matches = element.css('div.startDate').text.match(/(\d{4}).(\d{1,2}).(\d{1,2})/)
    board.created_at = Date.new(matches[1].to_i, matches[2].to_i, matches[3].to_i) if matches
    board
  end

  def recent?(offset = 7)
    return Date.today - offset <= @updated_at if @updated_at
    return Date.today - offset <= @created_at
  end

  def to_human
    <<~EOS
     【#{@name}】
      #{@title}    #{@url}
      更新日:#{@updated_at || @created_at}
    EOS
  end
  
  def to_h
    {
      name: @name,
      title: @title,
      url: @url,
      created_at: @created_at,
      updated_at: @updated_at,
    }
  end

  def to_s
    to_h.to_s
  end
end
