## 2024-05-20 - Addon Communication Denial of Service
**Vulnerability:** Addons processing remote events (`CHAT_MSG_ADDON`) can be exploited to spam the UI with popups, locking up the user's game client. Also user input wasn't being sanitized when printed.
**Learning:** Even when verifying channel sources (e.g. PARTY/RAID), malicious party members can send thousands of messages per second to freeze the target's client (a localized DoS).
**Prevention:** Implement strict time-based rate limiting per sender on any `CHAT_MSG_ADDON` handler that triggers UI popups or intensive computations. Also, always sanitize untrusted string inputs, particularly replacing UI color code escapes like `|` with `||`, before passing them to display functions.
