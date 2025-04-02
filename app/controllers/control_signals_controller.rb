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
      ::ControlExecution.create!(
        control_signal_id: control_signal.id,
        source: params[:source] || "manual",
        duration_ms: control_signal.length_ms || 3000,
        executed_at: Time.current
      )

      # Call the MQTT publish method (assuming this is defined somewhere)
      MqttListener.publish_control_command(control_signal)

      head :ok
    rescue => e
      Rails.logger.error "Trigger error: #{e.message}"
      head :unprocessable_entity
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
      :frequency, :unit, :enabled
    )
    end
end
