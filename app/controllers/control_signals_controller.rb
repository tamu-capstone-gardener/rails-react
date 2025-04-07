class ControlSignalsController < AuthenticatedApplicationController
    before_action :set_plant_module
    before_action :set_control_signal, only: [ :edit, :update ]

    def edit; end

    def update
      if @control_signal.update(control_signal_params)
        redirect_to plant_module_path(@plant_module), notice: "Control signal updated."
      else
        flash.now[:alert] = "Update failed."
        render :edit
      end
    end

    def trigger
      control_signal = ControlSignal.find(params[:id])

      MqttListener.publish_control_command(control_signal, toggle: params[:toggle] == "true", mode: "manual")

      sleep(1)

      last_exec = ControlExecution.where(control_signal_id: control_signal.id, source: "manual")
      .order(executed_at: :desc)
      .first


      if Time.now - last_exec.executed_at < 120
        flash[:success] = "Trigger succeeded"
      else
        flash[:alert] = "Trigger failed"
      end

      redirect_to plant_module_path(@plant_module)
    rescue => e
      Rails.logger.error "Trigger error: #{e.message}"
      render json: { error: "Trigger failed: #{e.message}" }, status: :unprocessable_entity
    end




    private

    def set_plant_module
      @plant_module = PlantModule.find(params[:plant_module_id])
    end

    def set_control_signal
      @control_signal = @plant_module.control_signals.find(params[:id])
    end

    def control_signal_params
      params.require(:control_signal).permit(
      :label, :signal_type, :delay, :length_ms,
      :mode, :sensor_id, :comparison, :threshold_value,
      :frequency, :unit, :enabled, :scheduled_time
    )
    end
end
