# Controller for managing control signals for plant modules
#
# This controller handles modification and triggering of control signals
# such as lights, water pumps, and fans for plant modules.
#
# @example Request to edit a control signal
#   GET /plant_modules/123/control_signals/456/edit
#
# @example Request to trigger a control signal
#   POST /control_signals/456/trigger
class ControlSignalsController < AuthenticatedApplicationController
    include ControlSignalsHelper
    before_action :set_plant_module
    before_action :set_control_signal, only: [ :edit, :update, :trigger ]

    # Displays the form to edit a control signal
    #
    # @param plant_module_id [String] ID of the plant module
    # @param id [String] ID of the control signal to edit
    # @return [void]
    def edit
      @length_unit = @control_signal.length_unit
      @length = @control_signal.length
    end

    # Updates a control signal
    #
    # @param plant_module_id [String] ID of the plant module
    # @param id [String] ID of the control signal to update
    # @param control_signal [Hash] control signal parameters
    # @return [void]
    def update
      # # Combine value and unit to compute length
      # length_unit  = params[:length_unit]

      # # Inject computed length into control_signal params
      # params[:control_signal][:length] = length


      if @control_signal.update(control_signal_params)
        redirect_to plant_module_path(@plant_module), success: "Control signal updated."
      else
        flash.now[:alert] = "Update failed."
        render :edit
      end
    end

    # Triggers a control signal to turn on or off
    #
    # @param id [String] ID of the control signal to trigger
    # @param toggle [String] "true" to toggle state, otherwise maintains current state
    # @return [void]
    def trigger
      # 1) flip the pump via MQTT
      last = @control_signal.control_executions.order(executed_at: :desc).first
      new_status = last.nil? ? true : !last.status
      MqttListener.publish_control_command(
        @control_signal,
        mode:     "manual",
        status:   new_status,
        duration: @control_signal.length
      )

        # 2) set a flash message for the view
        if new_status
          flash.now[:success] =
          "Turned #{@control_signal.label || @control_signal.signal_type} on " \
          "for #{format_duration(@control_signal.length, @control_signal.length_unit)}"
        else
          flash.now[:alert] =
          "Turned #{@control_signal.label || @control_signal.signal_type} off"
        end

      # 3) respond with Turbo Stream replacements
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            # update the flash frame
            turbo_stream.replace(
              "flash",
              partial: "shared/flash",
              locals:  { flash: flash }
            ),

            # replace just this signal's execution display
            turbo_stream.replace(
              "control_execution_#{@control_signal.id}",
              partial: "control_executions/control_execution",
              locals:  { signal: @control_signal, control_execution: @control_signal.control_executions.order(executed_at: :desc).first }
            ),

            # replace just this signal's toggle button
            turbo_stream.replace(
              "control_toggle_button_#{@control_signal.id}",
              partial: "control_signals/control_toggle_button",
              locals:  { signal: @control_signal.reload }
            )
          ]
        end

        # fallback for non-Turbo clients
        format.html do
          redirect_to plant_module_path(@plant_module), notice: flash[:success]
        end
      end

    rescue => e
      Rails.logger.error "Trigger error: #{e.message}"
      flash.now[:alert] = "Trigger failed: #{e.message}"
      render turbo_stream: turbo_stream.replace(
        "flash_messages",
        partial: "shared/flash",
        locals:  { flash: flash }
      ), status: :unprocessable_entity
    end

    private

    # Sets the plant module for the current request
    #
    # @return [void]
    def set_plant_module
      @plant_module = PlantModule.find(params[:plant_module_id])
    end

    # Sets the control signal for the current request
    #
    # @return [void]
    def set_control_signal
      @control_signal = @plant_module.control_signals.find(params[:id])
    end

    # Permits control signal parameters for mass assignment
    #
    # @return [ActionController::Parameters] permitted parameters
    def control_signal_params
      params.require(:control_signal).permit(
      :label, :signal_type, :delay, :length, :length_unit,
      :mode, :sensor_id, :comparison, :threshold_value,
      :frequency, :unit, :enabled, :scheduled_time
    )
    end
end
