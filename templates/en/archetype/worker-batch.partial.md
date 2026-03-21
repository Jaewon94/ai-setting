## Worker/Batch Rules
- All jobs must guarantee idempotency (same input, same result on re-run)
- Failed jobs must be designed for retry (dead letter queue, retry policy)
- Long-running jobs must leave heartbeat/checkpoints for progress tracking
- Resource cleanup: temporary files, DB connections, external sessions must be cleaned up with finally/defer
- Concurrency control: prevent duplicate execution on the same resource (lock, unique constraint, etc.)
- Logging: record job ID, start/end time, and processed count in structured logs
- Testing: single job unit tests + failure/retry scenario tests
