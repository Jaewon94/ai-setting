## Data/Automation Rules
- Validate input data schema before processing (type, range, null checks)
- Never modify original data -- transformation results go to separate output
- Design each pipeline stage to be independently re-runnable
- Be memory-conscious for large-scale processing -- prefer streaming/batch processing over full loading
- Results must be reproducible -- fix random seeds, record timestamps
- On failure, checkpoints/logs are required so you can tell how far processing got
- Testing: sample data-based pipeline tests + boundary value/missing value tests
