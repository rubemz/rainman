module Domain
  # This class handles interacting with the Enom API.
  class Enom
    def list(*a)
      :enom_list
    end

    # Transfer a domain name
    def transfer(*a)
      :enom_transfer
    end
  end
end
