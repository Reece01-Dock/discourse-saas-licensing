import DiscourseRoute from "discourse/routes/admin-route";
import { ajax } from "discourse/lib/ajax";

function fetchPackages() {
  return ajax("/saas/admin/license/packages");
}

function fetchOrganisations() {
  return ajax("/saas/admin/license/orgs");
}

function fetchSettings() {
  return ajax("/saas/admin/license/settings");
}

function fetchPurchases() {
  return ajax("/saas/admin/license/purchases");
}

export default class AdminPluginsSaasLicensingRoute extends DiscourseRoute {
  model() {
    return Promise.all([fetchPackages(), fetchOrganisations(), fetchSettings(), fetchPurchases()]).then(
      ([packages, organisations, settings, purchases]) => ({
        packages: packages.license_packages || [],
        organisations: organisations.organisations || [],
        settings: settings.settings || {},
        purchases: purchases.purchases || [],
      })
    );
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.setProperties({
      packages: model.packages,
      organisations: model.organisations,
      settings: model.settings,
      settingsForm: { ...model.settings },
      purchases: model.purchases,
      licenseForm: controller.blankLicense(),
    });
  }
}
