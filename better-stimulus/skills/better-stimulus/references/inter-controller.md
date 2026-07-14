# Inter-Controller Communication

Two patterns for making controllers talk to each other. Reach for the lightest one that works: prefer **custom events** for broadcasting, **outlets** for direct method calls, and **callbacks** only when a controller must pull data from another on demand.

## Outlets — Direct Controller-to-Controller Messaging

Use the Outlets API when one controller needs to call methods directly on other controller instances.

```html
<body data-controller="job-dashboard"
      data-job-dashboard-job-outlet=".job">
  <button data-action="job-dashboard#refresh"></button>
  <ul>
    <li data-controller="job" class="job"></li>
  </ul>
</body>
```

```js
// job_dashboard_controller.js
static outlets = ['job'];

refresh() {
  this.jobOutlets.forEach(outlet => outlet.update({...}));
}
```

Use outlets sparingly — outlet selectors in the HTML can become bloated. Prefer custom events when you only need to broadcast.

## Callbacks — Loose Controller Coupling

When one controller needs data from another without tight coupling, use a callback pattern (request/respond via events).

```js
// first_controller.js — exposes itself via a callback event
connect() {
  $(document).on('first_controller.state', (event, callback) => {
    callback(this);
  });
}
setName(value) { this.name = value; }

// second_controller.js — requests data when needed
render() {
  $(document).trigger('first_controller.state', firstController => {
    this.name = firstController.name;
  });
}
```
