import { useState, useEffect } from 'react';

/**
 * StatusTimeline Component
 * 
 * Purpose: Display a timeline of all status changes for a StatusUpdate
 * 
 * Props:
 *   - statusUpdateId: The ID of the status update to show timeline for
 * 
 * Data Flow:
 *   1. Component mounts
 *   2. useEffect hook fires (because of empty dependency array [])
 *   3. Fetches from: GET /api/v1/status_updates/:id/timeline
 *   4. API returns: { data: [ {from_status, to_status, changed_at, ...}, ... ] }
 *   5. Component stores in state: setChanges(response.data)
 *   6. Re-renders with the timeline
 */
function StatusTimeline({ statusUpdateId }) {
  // State: Declare variables that React tracks
  // When these change, React re-renders the component
  const [changes, setChanges] = useState([]);      // Timeline data starts empty
  const [loading, setLoading] = useState(true);    // Show loading state
  const [error, setError] = useState(null);        // Show errors if fetch fails

  // Effect: Run code ONCE when component mounts
  // Empty dependency array [] means "run only on mount"
  useEffect(() => {
    // STEP 1: Fetch the timeline data from Rails API
    fetch(`/api/v1/status_updates/${statusUpdateId}/timeline`)
      .then(response => {
        // Check if request succeeded (200, 201, etc.)
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        return response.json();  // Parse JSON response
      })
      .then(json => {
        // STEP 2: Store data in state (causes re-render)
        setChanges(json.data);   // json.data = [{from_status, to_status, ...}, ...]
        setLoading(false);
      })
      .catch(err => {
        // STEP 3: If anything fails, show error
        setError(err.message);
        setLoading(false);
      });
  }, [statusUpdateId]);  // If statusUpdateId changes, re-fetch

  // STEP 4: Render the UI
  
  if (loading) return <p>Loading timeline...</p>;
  if (error) return <p style={{ color: 'red' }}>Error: {error}</p>;
  if (changes.length === 0) return <p>No status changes yet.</p>;

  return (
    <div className="timeline-container">
      <h3>Status Timeline</h3>
      <div className="timeline">
        {/* Loop through each change and render a timeline item */}
        {changes.map((change, index) => (
          <div key={change.id} className="timeline-item">
            {/* Show an arrow connecting to next item (except last one) */}
            {index < changes.length - 1 && <div className="timeline-arrow">↓</div>}

            {/* The actual status change box */}
            <div className="timeline-event">
              {/* If this isn't the first change, show "from" status */}
              {change.from_status && (
                <div className="from-status">
                  📍 {change.status_display.from}
                </div>
              )}
              
              {/* Arrow between from/to */}
              <div className="status-arrow">→</div>

              {/* Show "to" status */}
              <div className="to-status">
                ✓ {change.status_display.to}
              </div>

              {/* Show when this happened */}
              <div className="timestamp">
                {new Date(change.changed_at).toLocaleString()}
              </div>

              {/* Show reason if provided */}
              {change.reason && (
                <div className="reason">
                  <em>"{change.reason}"</em>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default StatusTimeline;
