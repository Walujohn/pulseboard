require 'rails_helper'

# ==============================================================================
# Timeline API Tests
#
# Purpose: Verify the /api/v1/status_updates/:id/timeline endpoint works
#
# What we're testing:
#   ✓ The endpoint returns correct status code
#   ✓ The endpoint returns JSON with proper structure
#   ✓ The data is properly serialized (humanized labels, timestamps)
#   ✓ Changes are ordered chronologically (oldest first)
#   ✓ Handles missing status_updates (404)
#   ✓ Response format is consistent with other API endpoints (JsonResponses pattern)
#
# How this relates to the request-response cycle:
#   Request:  GET /api/v1/status_updates/:id/timeline
#   Route:    maps to StatusUpdatesController#timeline
#   Model:    fetches StatusChange records
#   Serialize: converts to JSON using StatusChangeSerializer
#   Response: returns { data: [...] } with proper status code
# ==============================================================================

RSpec.describe 'Timeline API', type: :request do
  let(:status_update) { create(:status_update) }

  describe 'GET /api/v1/status_updates/:id/timeline' do
    context 'with a valid status_update' do
      it 'returns 200 OK' do
        get timeline_api_v1_status_update_path(status_update)
        expect(response).to have_http_status(:ok)
      end

      it 'returns JSON response' do
        get timeline_api_v1_status_update_path(status_update)
        expect(response.content_type).to include('application/json')
      end

      it 'returns data envelope with changes array' do
        get timeline_api_v1_status_update_path(status_update)
        body = response.parsed_body

        expect(body).to have_key('data')
        expect(body['data']).to be_an(Array)
      end

      context 'when status_update has no changes' do
        it 'returns empty data array' do
          get timeline_api_v1_status_update_path(status_update)
          body = response.parsed_body

          expect(body['data']).to be_empty
        end
      end

      context 'when status_update has changes' do
        before do
          # Create changes in specific order
          @change1 = create(:status_change,
            status_update: status_update,
            from_status: nil,
            to_status: 'submitted'
          )
          sleep(0.01)
          @change2 = create(:status_change,
            status_update: status_update,
            from_status: 'submitted',
            to_status: 'in_review'
          )
        end

        it 'returns all changes for the status_update' do
          get timeline_api_v1_status_update_path(status_update)
          body = response.parsed_body

          expect(body['data'].length).to eq(2)
        end

        it 'returns changes in chronological order (oldest first)' do
          get timeline_api_v1_status_update_path(status_update)
          body = response.parsed_body

          expect(body['data'].first['to_status']).to eq('submitted')
          expect(body['data'].last['to_status']).to eq('in_review')
        end

        it 'includes change id' do
          get timeline_api_v1_status_update_path(status_update)
          body = response.parsed_body

          expect(body['data'].first).to have_key('id')
        end

        it 'includes from_status' do
          get timeline_api_v1_status_update_path(status_update)
          body = response.parsed_body

          expect(body['data'].first).to have_key('from_status')
        end

        it 'includes to_status' do
          get timeline_api_v1_status_update_path(status_update)
          body = response.parsed_body

          expect(body['data'].first).to have_key('to_status')
        end

        it 'includes changed_at timestamp' do
          get timeline_api_v1_status_update_path(status_update)
          body = response.parsed_body

          expect(body['data'].first).to have_key('changed_at')
        end

        it 'includes status_display with humanized labels' do
          get timeline_api_v1_status_update_path(status_update)
          body = response.parsed_body

          expect(body['data'].first).to have_key('status_display')
          expect(body['data'].first['status_display']).to have_key('from')
          expect(body['data'].first['status_display']).to have_key('to')
        end

        it 'humanizes status labels (submitted -> Submitted)' do
          get timeline_api_v1_status_update_path(status_update)
          body = response.parsed_body

          # First change has nil from_status, so from should be nil in display
          expect(body['data'].first['status_display']['to']).to eq('Submitted')
        end

        it 'handles multi-word statuses (in_review -> In Review)' do
          get timeline_api_v1_status_update_path(status_update)
          body = response.parsed_body

          expect(body['data'].last['status_display']['to']).to eq('In Review')
        end

        it 'includes reason when present' do
          change_with_reason = create(:status_change,
            status_update: status_update,
            from_status: 'in_review',
            to_status: 'approved',
            reason: 'Legal approved'
          )

          get timeline_api_v1_status_update_path(status_update)
          body = response.parsed_body

          # Find the change with reason
          change_data = body['data'].find { |c| c['to_status'] == 'approved' }
          expect(change_data['reason']).to eq('Legal approved')
        end

        it 'includes null reason when not present' do
          get timeline_api_v1_status_update_path(status_update)
          body = response.parsed_body

          # First change likely has no reason
          reason = body['data'].first['reason']
          expect([ nil, '' ]).to include(reason)
        end
      end
    end

    context 'with an invalid status_update id' do
      it 'returns 404 Not Found' do
        get timeline_api_v1_status_update_path(99999)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns error response' do
        get timeline_api_v1_status_update_path(99999)
        body = response.parsed_body

        expect(body).to have_key('error')
      end

      it 'includes error code' do
        get timeline_api_v1_status_update_path(99999)
        body = response.parsed_body

        expect(body['error']['code']).to eq('not_found')
      end

      it 'includes error message' do
        get timeline_api_v1_status_update_path(99999)
        body = response.parsed_body

        expect(body['error']).to have_key('message')
      end
    end
  end

  describe 'Response format consistency' do
    # These tests verify the JsonResponses concern is being used correctly

    it 'uses data envelope pattern (consistent with other API endpoints)' do
      get timeline_api_v1_status_update_path(status_update)
      body = response.parsed_body

      # Should have exactly one top-level key: 'data'
      expect(body.keys).to eq([ 'data' ])
    end

    it 'returns array in data, not nested object' do
      create(:status_change, status_update: status_update)
      get timeline_api_v1_status_update_path(status_update)
      body = response.parsed_body

      # Should be { data: [...] }, not { data: { changes: [...] } }
      expect(body['data']).to be_an(Array)
    end
  end

  describe 'Timestamp formatting' do
    # Timestamps should be ISO8601 format for API consistency

    it 'returns changed_at in ISO8601 format' do
      change = create(:status_change, status_update: status_update)
      get timeline_api_v1_status_update_path(status_update)
      body = response.parsed_body

      timestamp = body['data'].first['changed_at']
      # ISO8601 format looks like: 2026-01-17T10:30:45.123Z
      expect(timestamp).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end

    it 'includes timezone information' do
      change = create(:status_change, status_update: status_update)
      get timeline_api_v1_status_update_path(status_update)
      body = response.parsed_body

      timestamp = body['data'].first['changed_at']
      # Should end with Z (Zulu time / UTC)
      expect(timestamp).to end_with('Z')
    end

    it 'matches the actual created_at time' do
      change = create(:status_change, status_update: status_update)
      get timeline_api_v1_status_update_path(status_update)
      body = response.parsed_body

      # Parse the ISO8601 timestamp back to compare
      returned_time = Time.iso8601(body['data'].first['changed_at'])
      # Should be within 1 second (rounding differences)
      expect(returned_time).to be_within(1).of(change.created_at)
    end
  end
end
