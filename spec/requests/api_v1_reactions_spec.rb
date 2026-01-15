require 'rails_helper'

RSpec.describe 'Reactions API', type: :request do
  let(:status_update) { create(:status_update) }
  let(:user_id) { "test_user_123" }

  describe 'GET /api/v1/status_updates/:id/reactions' do
    context 'with no reactions' do
      it 'returns empty array' do
        get api_v1_status_update_reactions_path(status_update)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['data']).to eq([])
      end
    end

    context 'with reactions' do
      before do
        create(:reaction, status_update: status_update, emoji: "👍", user_identifier: "user_1")
        create(:reaction, status_update: status_update, emoji: "👍", user_identifier: "user_2")
        create(:reaction, status_update: status_update, emoji: "❤️", user_identifier: "user_3")
      end

      it 'returns grouped reactions with emoji, count, and users' do
        get api_v1_status_update_reactions_path(status_update)

        expect(response).to have_http_status(:ok)
        data = response.parsed_body['data']
        expect(data.length).to eq(2)

        thumbs_up = data.find { |r| r['emoji'] == '👍' }
        expect(thumbs_up['count']).to eq(2)
        expect(thumbs_up['users']).to include('user_1', 'user_2')

        heart = data.find { |r| r['emoji'] == '❤️' }
        expect(heart['count']).to eq(1)
      end
    end
  end

  describe 'POST /api/v1/status_updates/:id/reactions' do
    context 'with valid params' do
      it 'creates a reaction' do
        expect {
          post api_v1_status_update_reactions_path(status_update),
            params: { reaction: { emoji: "👍", user_identifier: user_id } }
        }.to change(Reaction, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body['data']['emoji']).to eq('👍')
        expect(response.parsed_body['data']['user_identifier']).to eq(user_id)
      end
    end

    context 'when toggling existing reaction' do
      before do
        create(:reaction, status_update: status_update, emoji: "👍", user_identifier: user_id)
      end

      it 'deletes the reaction and returns toggled: false' do
        expect {
          post api_v1_status_update_reactions_path(status_update),
            params: { reaction: { emoji: "👍", user_identifier: user_id } }
        }.to change(Reaction, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['data']['toggled']).to eq(false)
      end
    end

    context 'with invalid emoji' do
      it 'returns validation error' do
        post api_v1_status_update_reactions_path(status_update),
          params: { reaction: { emoji: "🚀", user_identifier: user_id } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']['messages']).to include("Emoji is not included in the list")
      end
    end

    context 'with missing user_identifier' do
      it 'returns validation error' do
        post api_v1_status_update_reactions_path(status_update),
          params: { reaction: { emoji: "👍" } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']['messages']).to include("User identifier can't be blank")
      end
    end
  end

  describe 'DELETE /api/v1/status_updates/:id/reactions/:reaction_id' do
    let(:reaction) { create(:reaction, status_update: status_update) }

    it 'deletes the reaction' do
      # Create reaction outside the change block
      reaction.reload

      delete api_v1_status_update_reaction_path(status_update, reaction)

      expect(response).to have_http_status(:ok)
      expect(Reaction.exists?(reaction.id)).to be false
      expect(response.parsed_body['success']).to eq(true)
    end

    it 'returns 404 for non-existent reaction' do
      delete api_v1_status_update_reaction_path(status_update, 'invalid')

      expect(response).to have_http_status(:not_found)
    end
  end
end
