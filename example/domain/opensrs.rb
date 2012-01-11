module Domain
  # This class handles interacting with the Opensrs API.
  class Opensrs
    def list(*a)
      :opensrs_list
    end

    # Transfer a domain name
    def transfer(*a)
      :opensrs_transfer
    end
  end
end
