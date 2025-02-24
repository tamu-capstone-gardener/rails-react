class PlantModulesController < AuthenticatedApplicationController
  def show
    @plant_module = PlantModule.find(params[:id])
  end

  def index
    @plant_modules = current_user.plant_modules
  end

  def test_create
    PlantModule.create!(
      id: SecureRandom.uuid,
      user_id: current_user.uid,
      name: "Example Module",
      description: "Module description here",
      location: "Module location"
    )

    redirect_to plant_modules_path, notice: "Module created successfully."
  end
end
