import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = []

  connect() {
    console.log("PWA install controller connected");
    this.deferredPrompt = null;
    window.addEventListener('beforeinstallprompt', this.handleBeforeInstallPrompt.bind(this));
    window.addEventListener('appinstalled', this.handleAppInstalled.bind(this));
    this.checkDisplayMode();
  }

  handleBeforeInstallPrompt(e) {
    // Prevent the mini-infobar from appearing on mobile
    e.preventDefault();
    // Stash the event so it can be triggered later.
    this.deferredPrompt = e;
    // Update UI to notify the user they can add to home screen
    this.element.classList.remove('hidden');
  }

  async install() {
    this.element.classList.add('hidden');
    if (this.deferredPrompt) {
      this.deferredPrompt.prompt();
      const { outcome } = await this.deferredPrompt.userChoice;
      console.log(`User response to the install prompt: ${outcome}`);
      this.deferredPrompt = null;
    }
  }

  dismiss() {
    console.log("Dismissing PWA install banner");
    this.element.classList.add('hidden');
    // Optionally, set a flag in sessionStorage to not show again
    sessionStorage.setItem('pwa_install_dismissed', 'true');
  }

  handleAppInstalled() {
    // Hide the install banner
    this.element.classList.add('hidden');
    // Clear the deferredPrompt so it can't be triggered again
    this.deferredPrompt = null;
  }

  checkDisplayMode() {
    console.log("Checking PWA display mode");
    if (window.matchMedia('(display-mode: standalone)').matches || navigator.standalone) {
      // App is running in standalone mode (installed)
      this.element.classList.add('hidden');
    } else if (sessionStorage.getItem('pwa_install_dismissed')) {
      // User previously dismissed the banner
      this.element.classList.add('hidden');
    }
  }
}