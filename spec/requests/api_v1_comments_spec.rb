require 'rails_helper'

RSpec.describe 'Comments API', type: :request do
  describe 'GET /api/v1/status_updates/:id/comments' do
    let(:status_update) { create(:status_update) }
    let!(:comment1) { create(:comment, status_update: status_update, body: 'First') }
    let!(:comment2) { create(:comment, status_update: status_update, body: 'Second') }

    it 'returns all comments for a status update' do
      get api_v1_status_update_comments_path(status_update)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['data'].length).to eq(2)
    end

    it 'returns comments in descending order' do
      get api_v1_status_update_comments_path(status_update)

      bodies = response.parsed_body['data'].map { |c| c['body'] }
      expect(bodies).to eq([ 'Second', 'First' ])
    end

    it 'supports pagination' do
      create_list(:comment, 3, status_update: status_update)

      get api_v1_status_update_comments_path(status_update), params: { per_page: 2 }

      expect(response.parsed_body['meta']['per_page']).to eq(2)
    end

    it 'filters comments by search query' do
      create(:comment, status_update: status_update, body: 'Completely different')

      get api_v1_status_update_comments_path(status_update), params: { q: 'First' }

      expect(response.parsed_body['data'].length).to eq(1)
      expect(response.parsed_body['data'][0]['body']).to include('First')
    end
  end

  describe 'POST /api/v1/status_updates/:id/comments' do
    let(:status_update) { create(:status_update) }

    it 'creates a comment' do
      post api_v1_status_update_comments_path(status_update),
        params: { comment: { body: 'Great post!' } }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['data']['body']).to eq('Great post!')
    end

    it 'returns validation errors for invalid comment' do
      post api_v1_status_update_comments_path(status_update),
        params: { comment: { body: '' } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']['messages']).to include("Body can't be blank")
    end
  end
end
