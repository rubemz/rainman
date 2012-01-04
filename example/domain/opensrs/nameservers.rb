module Domain
  # This class handles interacting with the Opensrs API's nameserver functions.
  class Opensrs::Nameservers

    # List domain nameservers
    def list(*a)
      :opensrs_ns_list
    end
  end
end
