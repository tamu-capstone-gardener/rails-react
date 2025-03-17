# PlantHub  

_This is a gardening assistant web appliation using Ruby on Rails, TailwindCSS, and StimulusJS. This web app works in conjunction with an ESP32 that acts as a hardware module to send signals for watering, lighting, etc. and sends sensor data such as soil moisture, temperature, etc. MQTT is used to facilitate this communication via a HiveMQ broker server._  

## Setup and Installation  

### Prerequisites  
Ensure you have the following installed:  
- **Ruby 3.4.1**  
- **Rails 8.0.1**  
- **PostgreSQL (version 9.3 or later)**  
- **Bundler** (`gem install bundler`)  

### Installation Steps  

1. **Clone the repository**  
   ```sh
   git clone https://github.com/tamu-capstone-gardener/rails-react.git
   cd rails-react
   ```

2. **Install dependencies**  
   ```sh
   bundle install
   ```

3. **Setup the database**  
   Ensure PostgreSQL is running, then run:  
   ```sh
   rails db:setup
   ```

4. **Run the application**  
   ```sh
   rails s
   ```

5. **Compile assets (if styles don’t load)**  
   ```sh
   rails assets:precompile
   ```

### Environment Configuration  
- Unless you have a preexisting user that uses default credentials with no password:
- Create a `.env` file for environment variables (or ensure they are set in your system).  
- The database connection settings are configured in `config/database.yml`, using:  
  - `POSTGRES_USER`  
  - `POSTGRES_PASSWORD`  

### Running Tests  
- Run the test suite using:  
  ```sh
  rspec
  ```  
- Check code style using:  
  ```sh
  rubocop
  ```  
