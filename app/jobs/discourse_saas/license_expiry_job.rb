module Jobs
  class DiscourseSaasLicenseExpiryJob < ::Jobs::Scheduled
    every 1.day

    def execute(_args)
      return if !SiteSetting.license_enabled

      DiscourseSaas::Purchase
        .where(active: true)
        .where("expires_at <= ?", Time.zone.now)
        .find_each do |purchase|
          purchase.expire!
        rescue StandardError => e
          Rails.logger.warn("[DiscourseSaas] Failed to expire purchase #{purchase.id}: #{e.message}")
        end
    end
  end
end
