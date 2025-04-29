require "pg"
require "pry"

class DatabasePersistence
  def initialize(logger)
    @db = if ENV["DATABASE_URL"]
      PG.connect(ENV["DATABASE_URL"])
    else
      PG.connect(dbname: "book_tracker")
    end
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def disconnect
    @db.close
  end

  def view_all_books
    sql = "SELECT * FROM books"
    result = query(sql)

    result.map do |tuple|
      tuple_to_hsh(tuple)
    end
  end

  def add_book(*params)
    sql = "INSERT INTO books (title, author, cover_image_url, start_date, finish_date, rating, review)
    VALUES ($1, $2, $3, $4, $5, $6, $7)"
    query(sql, params)
  end

  private

  def tuple_to_hsh(tuple)
    { id: tuple["id"].to_i,
      title: tuple["title"],
      author: tuple["author"],
      cover_image: tuple["cover_image_url"],
      start_date: tuple["start_date"],
      finish_date: tuple["finish_date"],
      rating: tuple["rating"].to_i,
      review: tuple["review"] }
  end
end
