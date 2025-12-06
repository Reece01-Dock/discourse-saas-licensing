import AdminPluginsSaasLicensingRoute from "discourse/plugins/discourse-saas-licensing/admin/routes/admin-plugins-saas-licensing";
import AdminPluginsSaasLicensingController from "discourse/plugins/discourse-saas-licensing/admin/controllers/admin-plugins-saas-licensing";
import template from "discourse/plugins/discourse-saas-licensing/admin/templates/admin-plugins-saas-licensing";

export default {
  name: "discourse-saas-licensing-admin",
  initialize() {
    // The imports above are enough for Ember to pick up the route/controller/template.
  },
};

export {
  AdminPluginsSaasLicensingRoute,
  AdminPluginsSaasLicensingController,
  template as AdminPluginsSaasLicensingTemplate,
};
