---
name: web-inspector
description: This skill should be used when the user asks to "open a website", "inspect a page", "take a screenshot of a URL", "check the console", "audit a page", "analyze network requests", "debug a webpage", "open in browser", or wants to interact with a live website using Chrome DevTools.
version: 1.0.0
---

# Web Inspector Skill

Use the `chrome-devtools` MCP server to open, inspect, and interact with websites in a live Chrome browser.

## Opening a Website

To open a URL in Chrome:

1. Call `new_page` to create a fresh tab (if needed)
2. Call `navigate_page` with the URL
3. Call `take_screenshot` to confirm the page loaded correctly

```
navigate_page(url: "https://example.com")
take_screenshot()
```

## Common Inspection Tasks

### Visual inspection
- `take_screenshot` — capture what the page looks like
- `take_snapshot` — capture the full DOM state

### Console & errors
- `list_console_messages` — list all console output (logs, warnings, errors)
- `get_console_message` — retrieve a specific console entry
- `evaluate_script` — run arbitrary JavaScript on the page

### Network activity
- `list_network_requests` — view all HTTP requests made by the page
- `get_network_request` — inspect a specific request/response in detail

### Performance & quality
- `lighthouse_audit` — run a Lighthouse audit (performance, accessibility, SEO, best practices)
- `performance_start_trace` + `performance_stop_trace` + `performance_analyze_insight` — record and analyze a performance trace
- `take_memory_snapshot` — capture a heap snapshot for memory analysis

### Page management
- `list_pages` — list all open tabs
- `select_page` — switch to a different tab
- `close_page` — close a tab

### Interaction
- `click`, `fill`, `type_text`, `press_key`, `hover` — interact with page elements
- `fill_form` — fill out an entire form at once
- `handle_dialog` — accept/dismiss browser dialogs
- `wait_for` — wait for a selector or condition before continuing
- `emulate` — simulate a mobile device or viewport
- `resize_page` — adjust the viewport size

## Workflow Examples

### Inspect a page for errors
```
navigate_page(url: "<url>")
take_screenshot()
list_console_messages()
list_network_requests()
```

### Run a full quality audit
```
navigate_page(url: "<url>")
lighthouse_audit()
```

### Debug a specific interaction
```
navigate_page(url: "<url>")
click(selector: "<button>")
list_console_messages()
take_screenshot()
```

## Notes

- Always `take_screenshot` after navigating so the user can see the result
- Use `list_pages` before `new_page` to avoid opening duplicate tabs
- `evaluate_script` can extract data from the DOM if no dedicated tool covers it
- The MCP server connects to a running Chrome instance — Chrome must be open
