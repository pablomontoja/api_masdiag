---
name: Stimulus Controller
description: Create Stimulus controllers for JavaScript interactivity
triggers:
  - stimulus
  - js controller
  - javascript controller
  - interactivity
---

# Stimulus Controller Creation

## Basic Pattern

```javascript
// app/javascript/controllers/example_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output"]
  static classes = ["active", "hidden"]
  static values = {
    url: String,
    refreshInterval: { type: Number, default: 5000 }
  }

  connect() {
    console.log("Controller connected")
  }

  disconnect() {
    console.log("Controller disconnected")
  }

  submit(event) {
    event.preventDefault()
    this.outputTarget.textContent = this.inputTarget.value
  }

  toggle() {
    this.element.classList.toggle(this.activeClass)
  }
}
```

## HTML Usage

```erb
<div data-controller="example"
     data-example-url-value="<%= api_path %>"
     data-example-active-class="bg-blue-500">

  <input data-example-target="input"
         data-action="input->example#submit">

  <button data-action="click->example#toggle">
    Toggle
  </button>

  <div data-example-target="output"></div>
</div>
```

## Common Patterns

### Toggle Visibility
```javascript
static targets = ["content"]

toggle() {
  this.contentTarget.classList.toggle("hidden")
}

show() {
  this.contentTarget.classList.remove("hidden")
}

hide() {
  this.contentTarget.classList.add("hidden")
}
```

### Debounce
```javascript
static targets = ["input"]
static values = { delay: { type: Number, default: 300 } }

search() {
  clearTimeout(this.timeout)
  this.timeout = setTimeout(() => {
    this.performSearch()
  }, this.delayValue)
}
```

### Fetch Data
```javascript
async load() {
  const response = await fetch(this.urlValue)
  const html = await response.text()
  this.outputTarget.innerHTML = html
}
```

## Generate Command
```bash
bin/rails generate stimulus controller_name
```
