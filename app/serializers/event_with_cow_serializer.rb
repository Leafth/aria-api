class EventWithCowSerializer < EventSerializer
  attributes :cow_name, :ear_tag

  def cow_name
    object.cow.name
  end

  def ear_tag
    object.cow.ear_tag
  end
end
