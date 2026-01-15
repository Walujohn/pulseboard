require 'rails_helper'

RSpec.describe 'Status Updates', type: :system do
  describe 'Creating a status update' do
    it 'creates a new status update and displays it on the page' do
      visit root_path

      fill_in 'Mood', with: 'happy'
      fill_in 'Body', with: 'Feeling great today!'
      click_button 'Post update'

      expect(page).to have_content('Feeling great today!')
      expect(page).to have_content('😊 Happy')
    end

    it 'displays validation errors when fields are missing' do
      visit root_path

      click_button 'Post update'

      expect(page).to have_content("can't be blank")
    end

    it 'displays validation error when body exceeds 280 characters' do
      visit root_path

      fill_in 'Mood', with: 'focused'
      fill_in 'Body', with: 'a' * 281
      click_button 'Post update'

      expect(page).to have_content('is too long')
    end
  end

  describe 'Editing a status update' do
    let(:status_update) { create(:status_update, body: 'Original text', mood: 'calm') }

    it 'updates the status update with new content' do
      visit root_path
      click_link 'Edit'

      fill_in 'Body', with: 'Updated text'
      click_button 'Post update'

      expect(page).to have_content('Updated text')
      expect(page).not_to have_content('Original text')
    end
  end

  describe 'Deleting a status update' do
    let(:status_update) { create(:status_update, body: 'Delete me') }

    it 'removes the status update from the page' do
      visit root_path

      accept_confirm do
        click_button 'Delete'
      end

      expect(page).not_to have_content('Delete me')
    end
  end

  describe 'Liking a status update' do
    let(:status_update) { create(:status_update, likes_count: 5) }

    it 'increments the like count' do
      visit root_path

      expect(page).to have_content('5')
      click_button '👍'

      expect(page).to have_content('6')
    end
  end

  describe 'Adding comments to a status update' do
    let(:status_update) { create(:status_update, body: 'Great update!') }

    it 'displays the comment form and allows adding comments' do
      visit root_path

      within first('.comments-section') do
        fill_in 'Add a comment:', with: 'Nice post!'
        click_button 'Post Comment'
      end

      expect(page).to have_content('Nice post!')
    end

    it 'displays validation errors for blank comments' do
      visit root_path

      within first('.comments-section') do
        click_button 'Post Comment'
      end

      expect(page).to have_content("can't be blank")
    end

    it 'displays comments in reverse chronological order' do
      comment1 = create(:comment, status_update: status_update, body: 'First comment', created_at: 2.hours.ago)
      comment2 = create(:comment, status_update: status_update, body: 'Second comment', created_at: 1.hour.ago)

      visit root_path

      comments = page.all('.comment__body').map(&:text)
      expect(comments.first).to include('Second comment')
      expect(comments.last).to include('First comment')
    end
  end

  describe 'Deleting a comment' do
    let(:status_update) { create(:status_update) }
    let(:comment) { create(:comment, status_update: status_update, body: 'Remove this') }

    it 'removes the comment from the page' do
      visit root_path

      accept_confirm do
        within first('.comment') do
          click_button 'Delete'
        end
      end

      expect(page).not_to have_content('Remove this')
    end
  end
end
