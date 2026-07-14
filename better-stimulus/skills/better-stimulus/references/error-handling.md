# Error Handling

## Global Error Handler via Application Controller

Catch all Stimulus and application errors in one place using a `handleError` hook on the base `ApplicationController`.

```js
// application_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  handleError = (error) => {
    const context = {
      controller: this.identifier,
      user_id: this.userId,
    };
    this.application.handleError(
      error,
      `Error in controller: ${this.identifier}`,
      context
    );
  };

  get userId() {
    return document.head.querySelector(`meta[name="user_id"]`)?.content;
  }
}

// some_controller.js
export default class extends ApplicationController {
  someFunc() {
    try {
      // ...
    } catch (err) {
      this.handleError(err);
    }
  }
}
```

Plug in an error reporting service (e.g. Sentry) at the application level so every caught error is forwarded:

```js
// application.js
const defaultErrorHandler = application.handleError.bind(application);
application.handleError = (error, message, detail = {}) => {
  defaultErrorHandler(error, message, detail);
  Sentry.captureException(error, { message, ...detail });
};
```
