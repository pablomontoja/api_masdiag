class ResultService < ApplicationService

  def initialize(options)
    @options = options
  end

  def call
    url = 'https://jsonplaceholder.typicode.com/posts'
    response = Faraday.post(url, {:title=>"Why I love Hitchhiker's Guide to the Galaxy", :body=>"42", :userId=>42})

  end
end
