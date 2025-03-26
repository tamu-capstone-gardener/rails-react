module PlantsHelper
    def render_star_rating(rating)
      if rating.present? && rating =~ /\((\d) of 5\)/
        stars = $1.to_i
      else
        stars = 0
      end
      full_stars = "★" * stars
      empty_stars = "☆" * (5 - stars)
      full_stars + empty_stars
    end
  end
  