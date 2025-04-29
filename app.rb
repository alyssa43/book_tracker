require "sinatra"
require "sinatra/content_for"
require "tilt/erubi"
require "net/http"
require "json"

require_relative "database_persistence"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end

before do
  @storage = DatabasePersistence.new(logger)
end

after do
  @storage.disconnect
end

def search_books(query)
  url = URI("https://www.googleapis.com/books/v1/volumes?q=#{URI.encode_www_form_component(query)}")
  response = Net::HTTP.get(url)
  data = JSON.parse(response)

  data["items"].map do |item|
    volume_info = item["volumeInfo"]
    {
      title: volume_info["title"],
      authors: volume_info["authors"]&.join(", ") || "Unknown",
      cover_image: volume_info.dig("imageLinks", "thumbnail") || "https://via.placeholder.com/128x193.png?text=No+Image",
      genres: volume_info["categories"]&.join(", ") || "Unkown"
    }
  end || []
end

get "/" do
  @books = @storage.view_all_books
  erb :index, layout: :layout
end

get "/search" do
  erb :search, layout: :layout
end

get "/search/results" do
  query = params[:title]

  @results = search_books(query)

  erb :search_results, layout: :layout
end

