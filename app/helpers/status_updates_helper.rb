module StatusUpdatesHelper
  def mood_emoji(mood)
    {
      "focused" => "🎯",
      "calm" => "😌",
      "happy" => "😊",
      "blocked" => "😤"
    }[mood] || "😐"
  end

  def mood_label(mood)
    "#{mood_emoji(mood)} #{mood.capitalize}"
  end
end
