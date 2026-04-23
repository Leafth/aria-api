class Bull < ApplicationRecord
  belongs_to :tenant
  belongs_to :company
end
