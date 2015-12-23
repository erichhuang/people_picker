class UserSerializer < ActiveModel::Serializer
  attributes :id, :uid, :first_name, :last_name, :email, :is_real, :is_persisted

  def is_persisted
    object.persisted?
  end
end
