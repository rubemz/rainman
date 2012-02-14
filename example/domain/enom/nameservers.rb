module Domain
  # This class handles interacting with the Enom API's nameserver functions.
  class Enom::Nameservers

    # List domain nameservers
    def self.list(*a)
      :enom_ns_list
    end
  end
end
