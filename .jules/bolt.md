## 2024-05-24 - Expensive Duplicate Encoding in Buffer Writing
**Learning:** Found an instance in `tools/streamtools.pas` where an expensive encoding function (`base64.EncodeStringBase64`) was called twice: once to get the data, and once to get its length for `WriteBuffer`. This results in $O(N)$ work and memory allocation being performed twice for a single operation.
**Action:** Always cache the result of expensive function calls (especially string manipulation/encoding) in a local variable if it needs to be accessed multiple times, particularly for length checks.
