module Dor
  class Collection < ::ActiveFedora::Base
    include Identifiable
    include Processable
    include Governable
    include Describable
    include Publishable

    has_relationship 'member', :is_member_of_collection, :inbound => true
    has_object_type 'collection'
  end
end