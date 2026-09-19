# Extension analysis points

| Field | Risk indicator |
|------|----------|
| host_permissions `<all_urls>` | Can read and write data on any site |
| webRequestBlocking | Can modify traffic as an intermediary |
| nativeMessaging | Can communicate with the local system outside the browser |
| externally_connectable | Web pages can control the extension |

MV3: Check the service_worker lifecycle and declarativeNetRequest.