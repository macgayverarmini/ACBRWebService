## 2024-05-18 - Redundant expensive base64 encoding evaluation
**Learning:** Found a function where `base64.EncodeStringBase64(TEncoding.UTF8.GetString(LBytes))` was evaluated twice: once to get the first character reference for writing to a buffer, and again to get the length. This doubles the CPU time and memory allocation overhead.
**Action:** Always cache the result of expensive transformations (like Base64 encoding or JSON serialization) into a local variable before using multiple aspects of the result (e.g. data buffer and length).
