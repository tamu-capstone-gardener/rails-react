module PlantsHelper
  def render_star_rating(rating)
    stars = rating.to_i.clamp(0, 5) # ensures it's between 0 and 5
    full_stars = "★" * stars
    empty_stars = "☆" * (5 - stars)
    full_stars + empty_stars
  end
end
