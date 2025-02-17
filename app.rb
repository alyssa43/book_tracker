require "sinatra"
require "sinatra/reloader"
require "tilt/erubi"
require "net/http"
require "json"
require "yaml"

def load_books
  YAML.load_file('books.yml', symbolize_names: true)
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
  @books = load_books
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

