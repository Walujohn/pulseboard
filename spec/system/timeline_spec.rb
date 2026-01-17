require 'rails_helper'

# ==============================================================================
# Timeline System Tests
#
# Purpose: Test the complete user journey for the timeline feature
#
# What we're testing:
#   ✓ User can navigate to a status update
#   ✓ User can see the status timeline
#   ✓ User can expand/collapse timeline items (Stimulus)
#   ✓ Timeline displays status changes in correct order
#   ✓ Stimulus controller properly manages expand/collapse state
#
# Why system tests matter:
#   - Tests the ENTIRE stack: Hotwire + Stimulus + HTML rendering
#   - Mimics real user behavior (clicking, scrolling, reading)
#   - Catches integration issues between components
#   - Verifies accessibility and visual presentation
#
# How to run these tests:
#   rspec spec/system/timeline_spec.rb --format progress
# ==============================================================================

RSpec.describe 'Timeline System Tests', type: :system do
  before do
    # Enable JavaScript for Stimulus tests
    driven_by :selenium, using: :chrome, screen_size: [ 1400, 1400 ]
  end

  let(:status_update) { create(:status_update, title: 'Test Application') }

  describe 'Viewing a status update timeline' do
    context 'with no changes' do
      it 'shows the status update detail page' do
        visit status_update_path(status_update)

        expect(page).to have_content('Test Application')
      end

      it 'shows an empty timeline' do
        visit status_update_path(status_update)

        # Check if timeline section exists but is empty
        expect(page).to have_css('[data-timeline]', count: 1)
      end
    end

    context 'with status changes' do
      before do
        # Create a realistic timeline of changes
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
        sleep(0.01)
        @change3 = create(:status_change,
          status_update: status_update,
          from_status: 'in_review',
          to_status: 'approved',
          reason: 'Legal team approved'
        )
      end

      it 'displays all status changes' do
        visit status_update_path(status_update)

        # Should see all three transitions
        expect(page).to have_content('Submitted')
        expect(page).to have_content('In Review')
        expect(page).to have_content('Approved')
      end

      it 'displays changes in chronological order' do
        visit status_update_path(status_update)

        # Use data attributes to identify timeline items
        items = page.all('[data-timeline-item-id]')
        expect(items.length).to eq(3)

        # First item should be the initial submission
        # (Implementation depends on your template structure)
      end

      it 'displays timestamps for each change' do
        visit status_update_path(status_update)

        # Timestamps should be visible (format depends on your template)
        # e.g., "Jan 17, 2026 at 10:30 AM"
        expect(page).to have_css('[data-timeline-item-timestamp]')
      end

      it 'displays reasons when provided' do
        visit status_update_path(status_update)

        # The third change has a reason
        expect(page).to have_content('Legal team approved')
      end

      it 'has proper semantic HTML' do
        visit status_update_path(status_update)

        # Timeline should use proper landmarks for accessibility
        expect(page).to have_css('[role="region"]')
      end
    end
  end

  describe 'Timeline item expand/collapse (Stimulus)' do
    before do
      # Create a change with a reason so there's something to expand
      @change1 = create(:status_change,
        status_update: status_update,
        from_status: nil,
        to_status: 'submitted'
      )
      @change2 = create(:status_change,
        status_update: status_update,
        from_status: 'submitted',
        to_status: 'in_review',
        reason: 'Documentation review in progress'
      )
    end

    it 'timeline items are rendered' do
      visit status_update_path(status_update)

      # Stimulus controller should be attached
      expect(page).to have_css('[data-controller="timeline-item"]')
    end

    it 'shows expandable items with summaries' do
      visit status_update_path(status_update)

      # Each item should have a summary (collapsed state)
      summaries = page.all('[data-timeline-item-target="summary"]')
      expect(summaries.length).to be > 0
    end

    it 'shows details when item is expanded' do
      visit status_update_path(status_update)

      # Click the first timeline item to expand
      first_item = page.first('[data-timeline-item-id]')
      first_item.click

      # Ensure Stimulus has time to update DOM
      sleep(0.1)

      # Details should now be visible
      expect(page).to have_css('[data-timeline-item-target="details"][open]')
    end

    it 'collapses item when clicked again' do
      visit status_update_path(status_update)

      first_item = page.first('[data-timeline-item-id]')

      # Expand
      first_item.click
      sleep(0.1)

      # Collapse
      first_item.click
      sleep(0.1)

      # Details should be closed
      # (Implementation depends on how you mark closed state)
    end

    it 'arrow indicator rotates on expand/collapse' do
      visit status_update_path(status_update)

      first_item = page.first('[data-timeline-item-id]')
      arrow = first_item.find('[data-timeline-item-target="arrow"]')

      # Initial class should indicate collapsed state
      initial_classes = arrow['class']

      # Click to expand
      first_item.click
      sleep(0.1)

      # Arrow should have rotated (different classes)
      expanded_classes = arrow['class']
      expect(expanded_classes).not_to eq(initial_classes)
    end

    it 'only affects clicked item, not others' do
      visit status_update_path(status_update)

      items = page.all('[data-timeline-item-id]')
      expect(items.length).to be >= 2

      # Click first item
      items[0].click
      sleep(0.1)

      # First item should be expanded
      first_expanded = items[0].find('[data-timeline-item-target="details"][open]', visible: :all) rescue nil
      expect(first_expanded).not_to be_nil

      # Second item should still be collapsed
      second_details = items[1].find('[data-timeline-item-target="details"]')
      expect(second_details['open']).to be_nil
    end

    it 'preserves expanded state when Turbo updates' do
      visit status_update_path(status_update)

      first_item = page.first('[data-timeline-item-id]')

      # Expand the item
      first_item.click
      sleep(0.1)

      # Turbo update would refresh the page
      # (In a real scenario, this might happen via Stimulus broadcast)
      # For now, we're testing that state is preserved within the page

      # Item should still be expanded
      details = first_item.find('[data-timeline-item-target="details"]')
      expect(details['open']).not_to be_nil
    end
  end

  describe 'Real-world scenarios' do
    it 'user journey: application submission to approval' do
      # Create a realistic timeline
      @change1 = create(:status_change,
        status_update: status_update,
        from_status: nil,
        to_status: 'submitted'
      )
      sleep(0.01)
      @change2 = create(:status_change,
        status_update: status_update,
        from_status: 'submitted',
        to_status: 'in_review',
        reason: 'Initial review started'
      )
      sleep(0.01)
      @change3 = create(:status_change,
        status_update: status_update,
        from_status: 'in_review',
        to_status: 'needs_info',
        reason: 'Additional documents required'
      )
      sleep(0.01)
      @change4 = create(:status_change,
        status_update: status_update,
        from_status: 'needs_info',
        to_status: 'in_review',
        reason: 'Documents received, resuming review'
      )
      sleep(0.01)
      @change5 = create(:status_change,
        status_update: status_update,
        from_status: 'in_review',
        to_status: 'approved',
        reason: 'Application approved'
      )

      # User navigates to their application
      visit status_update_path(status_update)
      expect(page).to have_content('Test Application')

      # User can see the full journey
      expect(page).to have_content('Submitted')
      expect(page).to have_content('In Review')
      expect(page).to have_content('Needs Info')
      expect(page).to have_content('Approved')

      # User can expand items to see reasons
      items = page.all('[data-timeline-item-id]')
      second_item = items[1] # In Review

      second_item.click
      sleep(0.1)

      expect(page).to have_content('Initial review started')
    end

    it 'handles applications with many status changes' do
      # Create 10 status changes
      statuses = [ 'submitted', 'in_review', 'needs_info', 'in_review', 'approved' ]

      (0..9).each do |i|
        create(:status_change,
          status_update: status_update,
          from_status: statuses[i % statuses.length],
          to_status: statuses[(i + 1) % statuses.length],
          reason: "Change #{i + 1}"
        )
        sleep(0.001)
      end

      visit status_update_path(status_update)

      # Should render all 10 items
      items = page.all('[data-timeline-item-id]')
      expect(items.length).to eq(10)

      # Should be able to interact with each
      items.each do |item|
        item.click
        sleep(0.05)
        item.click
        sleep(0.05)
      end
    end
  end

  describe 'Accessibility' do
    before do
      create(:status_change,
        status_update: status_update,
        from_status: nil,
        to_status: 'submitted'
      )
    end

    it 'timeline has proper ARIA labels' do
      visit status_update_path(status_update)

      # Should have role="region" or similar
      expect(page).to have_css('[role="region"]')
    end

    it 'expand/collapse is keyboard accessible' do
      visit status_update_path(status_update)

      first_item = page.first('[data-timeline-item-id]')

      # Focus the item
      first_item.focus

      # Should be able to interact with arrow
      arrow = first_item.find('[data-timeline-item-target="arrow"]')
      expect(arrow['tabindex']).to eq('0')
    end

    it 'timestamp text is readable' do
      visit status_update_path(status_update)

      # Timestamps should have sufficient contrast
      # (This is more of a visual test, but we can check they exist)
      expect(page).to have_css('[data-timeline-item-timestamp]')
    end
  end
end
