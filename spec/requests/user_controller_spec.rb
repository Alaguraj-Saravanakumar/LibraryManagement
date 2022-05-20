require 'rails_helper'

RSpec.describe "UserControllers", type: :request do


describe 'GET /users' do
  it 'should get index' do
    get('/users')
    assert_response :success
  end
end
  
end
