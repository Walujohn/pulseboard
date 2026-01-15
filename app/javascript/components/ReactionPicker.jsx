import React, { useState, useEffect } from 'react';

/**
 * REACT EXAMPLE: ReactionPicker Component
 * 
 * This demonstrates a React component that:
 * 1. Fetches data from a Rails API
 * 2. Manages local state with hooks
 * 3. Handles side effects with useEffect
 * 4. Makes POST/DELETE requests to the API
 * 5. Handles loading and error states
 * 
 * This is the "old way" - before converting to Hotwire
 */

const REACTION_EMOJIS = ["👍", "❤️", "😂", "😮", "😢", "🔥"];

export default function ReactionPicker({ statusUpdateId, userId }) {
  // State management
  const [reactions, setReactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [toggling, setToggling] = useState(null); // Track which emoji is being toggled

  // Fetch reactions on component mount
  useEffect(() => {
    fetchReactions();
  }, [statusUpdateId]);

  // API call to get all reactions
  const fetchReactions = async () => {
    try {
      setLoading(true);
      const response = await fetch(
        `/api/v1/status_updates/${statusUpdateId}/reactions`,
        {
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          }
        }
      );

      if (!response.ok) throw new Error('Failed to fetch reactions');
      
      const data = await response.json();
      setReactions(data.data || []);
      setError(null);
    } catch (err) {
      console.error('Error fetching reactions:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  // Handle emoji reaction click
  const handleReactionClick = async (emoji) => {
    try {
      setToggling(emoji);
      
      const response = await fetch(
        `/api/v1/status_updates/${statusUpdateId}/reactions`,
        {
          method: 'POST',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          body: JSON.stringify({
            reaction: {
              emoji: emoji,
              user_identifier: userId
            }
          })
        }
      );

      if (response.ok) {
        // Refetch reactions after successful toggle
        await fetchReactions();
      } else {
        const errorData = await response.json();
        setError(errorData.error?.messages?.[0] || 'Failed to add reaction');
      }
    } catch (err) {
      console.error('Error adding reaction:', err);
      setError(err.message);
    } finally {
      setToggling(null);
    }
  };

  if (loading) return <div className="reactions-picker--loading">Loading reactions...</div>;
  if (error) return <div className="reactions-picker--error">Error: {error}</div>;

  return (
    <div className="reactions-picker">
      <div className="reactions-picker__display">
        {reactions.length > 0 ? (
          reactions.map((reaction) => (
            <button
              key={reaction.emoji}
              className="reaction-button"
              onClick={() => handleReactionClick(reaction.emoji)}
              disabled={toggling === reaction.emoji}
              title={`${reaction.users.join(', ')} reacted with ${reaction.emoji}`}
            >
              <span className="reaction-emoji">{reaction.emoji}</span>
              <span className="reaction-count">{reaction.count}</span>
            </button>
          ))
        ) : (
          <p className="reactions-picker__empty">No reactions yet</p>
        )}
      </div>

      <div className="reactions-picker__options">
        <p className="reactions-picker__label">Add reaction:</p>
        <div className="emoji-options">
          {REACTION_EMOJIS.map((emoji) => (
            <button
              key={emoji}
              className="emoji-option"
              onClick={() => handleReactionClick(emoji)}
              disabled={toggling !== null}
              title={`React with ${emoji}`}
            >
              {emoji}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

/**
 * USAGE:
 * <ReactionPicker statusUpdateId={123} userId="user_session_123" />
 * 
 * CONCEPTS DEMONSTRATED:
 * - useState for managing reactions, loading, error states
 * - useEffect hook for side effects (fetching on mount)
 * - async/await for API calls
 * - Handling POST/GET requests
 * - Error handling
 * - Loading states
 * - Event handlers
 * - Conditional rendering
 */
