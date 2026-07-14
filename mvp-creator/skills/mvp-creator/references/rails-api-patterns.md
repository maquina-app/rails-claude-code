# Rails REST API Patterns

REST API patterns for Rails applications using ActiveRecord and JSON:API-style responses.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        API Consumers                                 │
│  Mobile apps, integrations, external systems                         │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    API V1 Controllers                                │
│  Api::V1::[Resource]Controller                                       │
│  - Inherits Api::BaseController                                      │
│  - Bearer token authentication                                       │
│  - Delegates serialization to model                                  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       Use Case Layer                                 │
│  [Resource]::Create, [Resource]::Update                              │
│  - Business logic encapsulation                                      │
│  - Returns { success:, resource:, error: }                           │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Model Layer                                   │
│  - Includes ApiSerializable concern                                  │
│  - Defines api_attributes for JSON output                            │
│  - Handles validations                                               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## File Structure

```
app/
├── controllers/
│   └── api/
│       ├── base_controller.rb
│       └── v1/
│           └── [resources]_controller.rb
├── models/
│   ├── concerns/
│   │   └── api_serializable.rb
│   └── [resource].rb
├── use_cases/
│   └── [resources]/
│       ├── create.rb
│       └── update.rb
│
config/
└── routes/
    └── api.rb
│
test/
└── controllers/
    └── api/
        └── v1/
            └── [resources]_controller_test.rb
```

---

## 1. ApiSerializable Concern

```ruby
# app/models/concerns/api_serializable.rb
module ApiSerializable
  extend ActiveSupport::Concern

  included do
    class_attribute :_api_attributes, default: []
    class_attribute :_api_methods, default: []
  end

  class_methods do
    # Define attributes exposed in API responses
    #
    # @param attrs [Array<Symbol>] attribute names
    # @param methods [Array<Symbol>] computed method names
    #
    def api_attributes(*attrs, methods: [])
      self._api_attributes = attrs
      self._api_methods = methods
    end
  end

  # Serialize model for API response
  #
  # @param include [Array<Symbol>] additional attributes
  # @param except [Array<Symbol>] attributes to exclude
  # @param methods [Boolean, Array<Symbol>] false to skip, or array to override
  # @return [Hash] serialized attributes with symbol keys
  #
  def as_api_json(include: [], except: [], methods: true)
    result = {}

    attrs = _api_attributes + Array(include) - Array(except)

    attrs.each do |attr|
      value = send(attr)
      result[attr] = format_value(value)
    end

    if methods
      method_list = methods == true ? _api_methods : Array(methods)
      method_list.each do |method_name|
        key = method_name.to_s.delete_suffix("?").to_sym
        result[key] = format_value(send(method_name))
      end
    end

    result
  end

  private

  def format_value(value)
    case value
    when Time, DateTime
      value.iso8601
    when Date
      value.iso8601
    when Hash
      value.transform_values { |v| format_value(v) }
    when Array
      value.map { |v| format_value(v) }
    else
      value
    end
  end
end
```

---

## 2. Model Pattern

```ruby
# app/models/location.rb
class Location < ApplicationRecord
  include ApiSerializable

  belongs_to :company
  has_many :bookings, dependent: :destroy

  # API Serialization
  api_attributes :id, :company_id, :name, :timezone, :phone, :email,
                 :address, :synced_at, :created_at, :updated_at,
                 methods: [:synced?, :active?]

  # Validations
  validates :name, presence: true
  validates :company_id, presence: true
  validates :timezone, presence: true
  validates :name, uniqueness: { scope: :company_id }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(name: :asc) }

  # Computed methods for API
  def synced?
    synced_at.present?
  end

  def active?
    active
  end
end
```

### Output

```ruby
location.as_api_json
# => {
#   id: 123,
#   company_id: 456,
#   name: "Downtown Clinic",
#   timezone: "America/Chicago",
#   phone: "+15125551234",
#   email: "clinic@example.com",
#   address: { street: "123 Main", city: "Austin" },
#   synced_at: "2025-01-15T10:00:00Z",
#   created_at: "2025-01-01T12:00:00Z",
#   updated_at: "2025-01-15T10:00:00Z",
#   synced: true,
#   active: true
# }
```

---

## 3. Base Controller

```ruby
# app/controllers/api/base_controller.rb
module Api
  class BaseController < ApplicationController
    protect_from_forgery with: :null_session
    before_action :authenticate_api_request

    private

    def authenticate_api_request
      token = request.headers["Authorization"]&.split(" ")&.last
      
      unless valid_token?(token)
        respond_with_error({ authentication: ["invalid or missing token"] }, status: :unauthorized)
      end
    end

    def valid_token?(token)
      return false if token.blank?
      ActiveSupport::SecurityUtils.secure_compare(token, Rails.application.credentials.api_token)
    end

    def respond_with_success(data, status: :ok)
      render json: { data: data, errors: {} }, status: status
    end

    def respond_with_error(errors, status: :unprocessable_entity)
      render json: { data: [], errors: errors }, status: status
    end

    def handle_unexpected_error(exception)
      Rails.logger.error("API Error: #{exception.message}\n#{exception.backtrace.first(5).join("\n")}")
      respond_with_error({ server: ["unexpected error"] }, status: :internal_server_error)
    end
  end
end
```

---

## 4. Routes Configuration

```ruby
# config/routes/api.rb
namespace :api, defaults: { format: :json } do
  namespace :v1 do
    resources :locations, only: %i[index show create update destroy] do
      resources :bookings, only: [:index], controller: "locations/bookings"
    end

    resources :bookings, only: %i[create show destroy]
  end
end
```

---

## 5. Controller Pattern

```ruby
# app/controllers/api/v1/locations_controller.rb
module Api
  module V1
    class LocationsController < Api::BaseController
      before_action :set_location, only: %i[show update destroy]

      # GET /api/v1/locations
      def index
        locations = Location.active.ordered

        respond_with_success(locations.map { |loc| serialize_location(loc) })
      rescue StandardError => e
        handle_unexpected_error(e)
      end

      # GET /api/v1/locations/:id
      def show
        respond_with_success([serialize_location(@location)])
      end

      # POST /api/v1/locations
      def create
        # Phase 1: Bad Request checks (400)
        bad_request_errors = validate_required_params
        return respond_with_error(bad_request_errors, status: :bad_request) if bad_request_errors

        # Phase 2: Create and save (model validations → 422)
        location = Location.new(location_params)

        if location.save
          respond_with_success([serialize_location(location)], status: :created)
        else
          respond_with_error(location.errors.to_hash, status: :unprocessable_entity)
        end
      rescue ActiveRecord::RecordNotUnique => e
        respond_with_error({ name: ["already exists for this company"] }, status: :unprocessable_entity)
      rescue StandardError => e
        handle_unexpected_error(e)
      end

      # PATCH/PUT /api/v1/locations/:id
      def update
        if @location.update(location_params)
          respond_with_success([serialize_location(@location)])
        else
          respond_with_error(@location.errors.to_hash, status: :unprocessable_entity)
        end
      rescue StandardError => e
        handle_unexpected_error(e)
      end

      # DELETE /api/v1/locations/:id
      def destroy
        @location.destroy
        respond_with_success([{ id: @location.id, deleted: true }])
      rescue StandardError => e
        handle_unexpected_error(e)
      end

      private

      def set_location
        @location = Location.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        respond_with_error({ location: ["not found"] }, status: :not_found)
      end

      def serialize_location(location)
        result = location.as_api_json
        result[:company] = serialize_company(location.company) if include_company?
        result
      end

      def include_company?
        params[:include]&.split(",")&.include?("company")
      end

      def serialize_company(company)
        return nil unless company
        { id: company.id, name: company.name, timezone: company.timezone }
      end

      def location_params
        params.permit(:company_id, :name, :timezone, :phone, :email, :active,
                      address: %i[street city state zip country])
      end

      # 400 Bad Request validations
      def validate_required_params
        errors = {}
        errors[:company_id] = ["is required"] if params[:company_id].blank?
        errors[:name] = ["is required"] if params[:name].blank?
        errors[:timezone] = ["is required"] if params[:timezone].blank?

        return errors if errors.any?

        validate_company_exists
      end

      def validate_company_exists
        Company.find(params[:company_id])
        nil
      rescue ActiveRecord::RecordNotFound
        { company_id: ["not found"] }
      end
    end
  end
end
```

---

## 6. Response Format

### Standard Structure

```json
{
  "data": [...],
  "errors": {}
}
```

### Success Examples

```ruby
# Collection
respond_with_success(resources.map(&:as_api_json))

# Single item (wrapped in array for consistency)
respond_with_success([resource.as_api_json])

# Created (201)
respond_with_success([resource.as_api_json], status: :created)

# Deleted
respond_with_success([{ id: resource.id, deleted: true }])
```

### Error Examples

```ruby
# 400 Bad Request (missing params)
respond_with_error({ field: ["is required"] }, status: :bad_request)

# 401 Unauthorized
respond_with_error({ authentication: ["invalid token"] }, status: :unauthorized)

# 404 Not Found
respond_with_error({ resource: ["not found"] }, status: :not_found)

# 422 Unprocessable Entity (model errors)
respond_with_error(resource.errors.to_hash, status: :unprocessable_entity)
```

---

## 7. HTTP Status Codes

| Status | Symbol                  | When to Use                                    |
|--------|-------------------------|------------------------------------------------|
| 200    | `:ok`                   | Successful GET, PUT, PATCH, DELETE             |
| 201    | `:created`              | Successful POST (resource created)             |
| 400    | `:bad_request`          | Missing required fields, parent not found      |
| 401    | `:unauthorized`         | Invalid or missing authentication              |
| 404    | `:not_found`            | Resource with given ID doesn't exist           |
| 422    | `:unprocessable_entity` | Duplicates, model validation failures          |
| 500    | `:internal_server_error`| Unexpected errors                              |

### Decision Tree

```
Is the request malformed or incomplete?
├── YES → 400 Bad Request
│   - Missing required field
│   - Referenced parent not found
│
└── NO → Is it a business rule violation?
    ├── YES → 422 Unprocessable Entity
    │   - Duplicate record
    │   - Model validation failure
    │
    └── NO → Is the resource not found?
        ├── YES → 404 Not Found
        └── NO → 500 Internal Server Error
```

---

## 8. Two-Phase Validation

```ruby
def create
  # Phase 1: Bad Request checks (400)
  # - Required fields present
  # - Referenced resources exist
  bad_request_errors = validate_required_params
  return respond_with_error(bad_request_errors, status: :bad_request) if bad_request_errors

  # Phase 2: Model save (422 on validation failures)
  resource = Model.new(permitted_params)
  if resource.save
    respond_with_success([resource.as_api_json], status: :created)
  else
    respond_with_error(resource.errors.to_hash, status: :unprocessable_entity)
  end
end
```

---

## 9. Use Cases for Complex Operations

```ruby
# app/use_cases/bookings/create.rb
module Bookings
  class Create
    def initialize(location:, service:, patient_id:, start_time:, end_time:)
      @location = location
      @service = service
      @patient_id = patient_id
      @start_time = start_time
      @end_time = end_time
    end

    def call
      validate!
      booking = build_booking

      if booking.save
        schedule_confirmation_email(booking)
        success(booking)
      else
        failure(booking.errors.full_messages.first)
      end
    rescue ValidationError => e
      failure(e.message)
    end

    private

    def validate!
      raise ValidationError, "Location is inactive" unless @location.active?
      raise ValidationError, "Time slot unavailable" unless slot_available?
    end

    def success(booking)
      { success: true, booking: booking, error: nil }
    end

    def failure(message)
      { success: false, booking: nil, error: message }
    end
  end
end
```

### Controller Usage

```ruby
def create
  validation_error = validate_required_params
  return respond_with_error(validation_error, status: :bad_request) if validation_error

  result = Bookings::Create.new(
    location: @location,
    service: @service,
    patient_id: params[:patient_id],
    start_time: params[:start_time],
    end_time: params[:end_time]
  ).call

  if result[:success]
    respond_with_success([result[:booking].as_api_json], status: :created)
  else
    respond_with_error({ booking: [result[:error]] }, status: :unprocessable_entity)
  end
end
```

---

## 10. Testing Pattern

```ruby
# test/controllers/api/v1/locations_controller_test.rb
require "test_helper"

class Api::V1::LocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{Rails.application.credentials.api_token}"
    }
    @company = companies(:acme)
  end

  test "GET /api/v1/locations returns unauthorized without token" do
    get api_v1_locations_url, headers: @headers.except("Authorization")
    assert_response :unauthorized
  end

  test "GET /api/v1/locations returns active locations" do
    location = locations(:downtown)

    get api_v1_locations_url, headers: @headers

    assert_response :ok
    json = response.parsed_body
    assert_includes json["data"].map { |l| l["id"] }, location.id
  end

  test "POST /api/v1/locations creates location" do
    params = { company_id: @company.id, name: "New Location", timezone: "America/Chicago" }

    assert_difference "Location.count", 1 do
      post api_v1_locations_url, params: params.to_json, headers: @headers
    end

    assert_response :created
    assert_equal "New Location", response.parsed_body["data"].first["name"]
  end

  test "POST /api/v1/locations returns 400 when company_id missing" do
    params = { name: "New Location", timezone: "America/Chicago" }

    post api_v1_locations_url, params: params.to_json, headers: @headers

    assert_response :bad_request
    assert_includes response.parsed_body["errors"]["company_id"], "is required"
  end

  test "POST /api/v1/locations returns 422 for duplicate" do
    existing = locations(:downtown)
    params = { company_id: existing.company_id, name: existing.name, timezone: "America/Chicago" }

    post api_v1_locations_url, params: params.to_json, headers: @headers

    assert_response :unprocessable_entity
  end
end
```

---

## 11. Implementation Checklist

### Model Setup
- [ ] Include `ApiSerializable` concern
- [ ] Define `api_attributes` with fields and methods
- [ ] Add model validations
- [ ] Add computed methods (e.g., `synced?`, `active?`)

### Routes
- [ ] Add namespace to routes file
- [ ] Define resource routes with actions

### Controller
- [ ] Inherit from `Api::BaseController`
- [ ] Implement CRUD actions
- [ ] Use `model.as_api_json` for serialization
- [ ] Implement two-phase validation (400 vs 422)
- [ ] Handle `ActiveRecord::RecordNotFound`
- [ ] Handle `ActiveRecord::RecordNotUnique`

### Tests
- [ ] Test authentication (401)
- [ ] Test successful operations (200, 201)
- [ ] Test 400 errors (missing params)
- [ ] Test 404 errors (invalid ID)
- [ ] Test 422 errors (duplicates, validation)

---

## Quick Reference

### Model

```ruby
include ApiSerializable

api_attributes :id, :name, :email, :created_at, :updated_at,
               methods: [:active?, :synced?]
```

### Controller

```ruby
# Serialize
resource.as_api_json
resource.as_api_json(include: [:settings])
resource.as_api_json(except: [:internal_field])

# Respond
respond_with_success([resource.as_api_json], status: :created)
respond_with_error(resource.errors.to_hash, status: :unprocessable_entity)
```

### Status Codes

```ruby
status: :ok                   # 200
status: :created              # 201
status: :bad_request          # 400
status: :unauthorized         # 401
status: :not_found            # 404
status: :unprocessable_entity # 422
```
