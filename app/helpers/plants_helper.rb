# Helper methods for plant-related views
#
# This module provides methods for formatting plant data in views
module PlantsHelper
  # Renders a visual star rating
  #
  # @param rating [Integer, String] the numeric rating (0-5)
  # @return [String] HTML-safe string with filled and empty star symbols
  # @example
  #   render_star_rating(3) # => "★★★☆☆"
  def render_star_rating(rating)
    stars = rating.to_i.clamp(0, 5) # ensures it's between 0 and 5
    full_stars = "★" * stars
    empty_stars = "☆" * (5 - stars)
    full_stars + empty_stars
  end

  # Cleans up array strings from JSON format
  #
  # @param raw [String] raw array string (e.g., "[1,2,3]")
  # @return [String] cleaned string without brackets and quotes
  # @example
  #   clean_array_string("[1,2,3]") # => "1,2,3"
  def clean_array_string(raw)
    raw.to_s.gsub(/[\[\]'"]/, "").strip
  end
end
