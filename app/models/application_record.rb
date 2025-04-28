# Base class for all models in the application
#
# @abstract Serves as the abstract base class that all models inherit from
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
