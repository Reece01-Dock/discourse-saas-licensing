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

export default class AdminPluginsSaasLicensingRoute extends DiscourseRoute {
  model() {
    return Promise.all([fetchPackages(), fetchOrganisations(), fetchSettings()]).then(
      ([packages, organisations, settings]) => ({
        packages: packages.license_packages || [],
        organisations: organisations.organisations || [],
        settings: settings.settings || {},
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
    });
  }
}
