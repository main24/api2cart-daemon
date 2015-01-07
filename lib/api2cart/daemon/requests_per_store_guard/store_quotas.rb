module Api2cart::Daemon
  class RequestsPerStoreGuard::StoreQuotas
    def initialize
      self.quotas = Hash.new(0)
    end

    def has_quota?(store_key)
      quotas[store_key] >= 1
    end

    def use_quota!(store_key)
      quotas[store_key] -= 1
    end

    def replenish_quota!(store_key)
      quotas[store_key] = 5
    end

    protected

    attr_accessor :quotas
  end
end
