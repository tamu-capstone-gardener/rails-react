class HomeController < AuthenticatedApplicationController
  def welcome
    @plant_modules = PlantModule.all
  end
end
