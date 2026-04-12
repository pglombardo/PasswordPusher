import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "menuButtonInner", "field" ]

  select(event) {
    this.fieldTarget.value = event.currentTarget.dataset.lang;
    const template = event.currentTarget.querySelector('template');
    this.menuButtonInnerTarget.innerHTML = template.innerHTML
  }
}
