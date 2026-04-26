import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "menuButtonInner", "field" ]

  connect() {
    this.restoreSelectedValue();
  }

  select(event) {
    this.fieldTarget.value = event.currentTarget.dataset.lang;
    const template = event.currentTarget.querySelector('template');
    this.menuButtonInnerTarget.innerHTML = template.innerHTML
  }

  restoreSelectedValue() {
    const selectedLang = this.fieldTarget.value;
    if (selectedLang) {
      const selectedOption = this.element.querySelector(`[data-lang="${selectedLang}"]`);
      if (selectedOption) {
        const template = selectedOption.querySelector('template');
        if (template) {
          this.menuButtonInnerTarget.innerHTML = template.innerHTML;
        }
      }
    }
  }
}
