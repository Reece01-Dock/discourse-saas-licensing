import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "discourse-saas-licensing-admin-route",
  initialize() {
    withPluginApi("0.11.1", (api) => {
      api.addAdminRoute("saas_licensing.title", "saas-licensing");
    });
  },
};
