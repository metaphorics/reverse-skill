# Automation Entry

Recommended start sequence:

1. Use `js-reverse_new_page` or `js-reverse_navigate_page` to open the page.
2. Use `js-reverse_list_network_requests` to view recent requests.
3. Use `js-reverse_get_request_initiator` to find the call stack.
4. Use `js-reverse_list_scripts` to define the script scope.
5. Use `js-reverse_search_in_sources` to search for request paths, parameter names, and function names.
6. Use `js-reverse_break_on_xhr` or `js-reverse_set_breakpoint_on_text` if necessary.

By default, do not start by guessing how to supply missing parts of `window`, `document`, or `navigator`.