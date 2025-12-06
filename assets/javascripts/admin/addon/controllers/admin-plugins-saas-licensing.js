import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { notifySuccess } from "discourse/lib/notification";

export default class AdminPluginsSaasLicensingController extends Controller {
  @tracked packages = [];
  @tracked organisations = [];
  @tracked editingPackage = null;
  @tracked packageForm = this.blankPackage();
  @tracked settings = {};
  @tracked settingsForm = {};
  @tracked invitee = "";

  blankPackage() {
    return {
      name: "",
      price_cents: 0,
      duration_days: 30,
      seats: 1,
      group_id: null,
      is_org_license: false,
    };
  }

  @action refresh() {
    Promise.all([
      ajax("/saas/admin/license/packages"),
      ajax("/saas/admin/license/orgs"),
      ajax("/saas/admin/license/settings"),
    ]).then(([packages, organisations, settings]) => {
      this.packages = packages.license_packages || [];
      this.organisations = organisations.organisations || [];
      this.settings = settings.settings || {};
      this.settingsForm = { ...this.settings };
    }, popupAjaxError);
  }

  @action editPackage(pkg) {
    this.editingPackage = pkg;
    this.packageForm = { ...pkg };
  }

  @action resetForm() {
    this.editingPackage = null;
    this.packageForm = this.blankPackage();
  }

  @action updateOrgLicense(event) {
    this.packageForm = {
      ...this.packageForm,
      is_org_license: event?.target?.checked,
    };
  }

  @action savePackage(event) {
    event?.preventDefault();
    const payload = { license_package: this.packageForm };
    const path = this.editingPackage
      ? `/saas/admin/license/packages/${this.editingPackage.id}`
      : "/saas/admin/license/packages";
    const method = this.editingPackage ? "PUT" : "POST";

    ajax(path, { method, data: payload })
      .then((result) => {
        notifySuccess(this.editingPackage ? "Package updated" : "Package created");
        this.refresh();
        this.resetForm();
        if (result.license_package) {
          this.editingPackage = result.license_package;
        }
      })
      .catch(popupAjaxError);
  }

  @action saveSettings(event) {
    event?.preventDefault();
    ajax("/saas/admin/license/settings", {
      method: "PUT",
      data: { settings: this.settingsForm },
    })
      .then((result) => {
        this.settings = result.settings || {};
        this.settingsForm = { ...this.settings };
        notifySuccess("Settings updated");
      })
      .catch(popupAjaxError);
  }

  @action updateSettingCheckbox(key, event) {
    this.settingsForm = {
      ...this.settingsForm,
      [key]: !!event?.target?.checked,
    };
  }

  @action deletePackage(pkg) {
    if (!window.confirm("Delete this package?")) {
      return;
    }
    ajax(`/saas/admin/license/packages/${pkg.id}`, { method: "DELETE" })
      .then(() => {
        notifySuccess("Package deleted");
        this.refresh();
      })
      .catch(popupAjaxError);
  }

  @action inviteMember(org, event) {
    event?.preventDefault();
    if (!this.invitee) {
      return;
    }

    ajax(`/saas/admin/license/orgs/${org.id}/invite`, {
      method: "POST",
      data: { username_or_email: this.invitee },
    })
      .then(() => {
        notifySuccess("Member invited");
        this.invitee = "";
        this.refresh();
      })
      .catch(popupAjaxError);
  }

  @action removeMember(org, userId) {
    ajax(`/saas/admin/license/orgs/${org.id}/member/${userId}`, { method: "DELETE" })
      .then(() => {
        notifySuccess("Member removed");
        this.refresh();
      })
      .catch(popupAjaxError);
  }
}
