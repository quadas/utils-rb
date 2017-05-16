class Address < ActiveRecord::Base
end

class Activity < ActiveRecord::Base
  serialize :content, Hash
  belongs_to :auditable, polymorphic: true
end
