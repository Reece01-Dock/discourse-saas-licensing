module DiscourseSaas
  class StripeController < ::DiscourseSaas::ApplicationController
    skip_before_action :verify_authenticity_token

    def webhook
      payload = request.body.read
      event = parse_event(payload)

      case event["type"]
      when "checkout.session.completed"
        handle_checkout_session(event["data"]["object"])
      else
        Rails.logger.info("[DiscourseSaas] Ignoring Stripe event type=#{event['type']}")
      end

      render_json_dump(success: true)
    rescue StandardError => e
      Rails.logger.warn("[DiscourseSaas] Stripe webhook failure: #{e.message}")
      render_json_error(e.message, status: 400)
    end

    private

    def parse_event(payload)
      if defined?(Stripe)
        sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
        signing_secret = SiteSetting.stripe_webhook_secret.presence
        if signing_secret.present? && sig_header.present?
          return DiscourseSaas.stripe_client::Webhook.construct_event(payload, sig_header, signing_secret)
        end
      end
      JSON.parse(payload)
    end

    def handle_checkout_session(session)
      meta = session["metadata"] || {}
      package_id = meta["license_package_id"]
      user_id = meta["user_id"]
      organisation_name = meta["organisation_name"]

      raise Discourse::InvalidParameters.new(:license_package_id) if package_id.blank?
      raise Discourse::InvalidParameters.new(:user_id) if user_id.blank?

      user = User.find_by(id: user_id)
      package = DiscourseSaas::LicensePackage.find_by(id: package_id)
      raise Discourse::NotFound if user.blank? || package.blank?

      expires_at = package.duration_days.days.from_now

      purchase =
        DiscourseSaas::Purchase.create!(
          user_id: user.id,
          license_package_id: package.id,
          stripe_session_id: session["id"],
          expires_at: expires_at,
          active: true,
        )

      purchase.grant_access!
      create_org_for_purchase!(purchase, organisation_name) if package.is_org_license
      purchase
    end

    def create_org_for_purchase!(purchase, organisation_name)
      package = purchase.license_package
      owner = purchase.user
      group =
        Group.create!(
          name: unique_group_name(owner, organisation_name || package.name),
          visibility_level: Group.visibility_levels[:staff],
        )

      organisation =
        DiscourseSaas::Organisation.create!(
          name: organisation_name.presence || package.name,
          owner_id: owner.id,
          group_id: group.id,
          seats_total: package.seats,
          seats_used: 0,
          active: true,
        )
      purchase.update!(organisation_id: organisation.id)
      organisation.add_member!(owner, added_by: owner)
    end

    def unique_group_name(owner, base_name)
      slug = base_name.to_s.parameterize.presence || "org"
      "org_#{slug}_#{owner.id}_#{SecureRandom.hex(2)}"
    end
  end
end
