import { Controller } from "@hotwired/stimulus"
import { debounce } from "helpers/timing_helpers";
import { post } from "@rails/request.js"

export default class extends Controller {
  static classes = ["filtersSet"]
  static targets = ["field", "form"]
  static values = { refreshSaveToggleUrl: String }

  initialize() {
    this.debouncedChange = debounce(this.change.bind(this), 50)
  }

  connect() {
    this.change()
  }

  change() {
    this.#toggleFiltersSetClass()
    this.#refreshSaveToggleButton()
  }

  async fieldTargetConnected(field) {
    this.debouncedChange()
  }

  #toggleFiltersSetClass(shouldAdd) {
    this.element.classList.toggle(this.filtersSetClass, this.#hasFiltersSet)
  }

  get #hasFiltersSet() {
    return this.fieldTargets.some(field => this.#isFieldSet(field))
  }

  #isFieldSet(field) {
    const value = field.value?.trim()

    if (!value) return false

    const defaultValue = this.#defaultValueForField(field)
    return defaultValue ? value !== defaultValue : true
  }

  #defaultValueForField(field) {
    const comboboxContainer = field.closest("[data-combobox-default-value-value]")
    return comboboxContainer?.dataset?.comboboxDefaultValueValue
  }

  #refreshSaveToggleButton() {
    post(this.refreshSaveToggleUrlValue, {
      body: this.#collectFilterFormData(),
      responseKind: "turbo-stream"
    })
  }

  #collectFilterFormData() {
    const formData = new FormData()

    this.formTargets.forEach(form => {
      const hiddenFields = form.querySelectorAll('input[type="hidden"]:not([disabled])[name]')
      hiddenFields.forEach(field => {
        formData.append(field.name, field.value)
      })
    })

    return formData
  }
}
