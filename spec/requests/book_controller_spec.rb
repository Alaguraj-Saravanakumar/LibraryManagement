require 'rails_helper'

RSpec.describe "BookControllers", type: :request do
   it "should get index" do
   get books_url
   assert_response :success
  end
end
