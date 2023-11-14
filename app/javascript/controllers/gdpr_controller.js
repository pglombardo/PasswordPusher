import { Controller } from "@hotwired/stimulus"
import Cookies from 'js-cookie'

export default class extends Controller {
    static targets = [ 'cookieBanner' ]

    static values = { }

    connect() {
      if (!Cookies.get('cookieConsent')) {
        let cookieBanner = this.cookieBannerTarget;
        cookieBanner.style.display = 'block';
      }
    }

     acceptCookies(event) {
          Cookies.set('cookieConsent', 'true', 365);
          let cookieBanner = this.cookieBannerTarget;
          cookieBanner.style.display = 'none';
     }
}
