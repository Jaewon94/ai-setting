## Library/SDK Rules
- Keep the public API surface minimal -- do not expose internal implementations
- All public functions/classes require type definitions and docstring/JSDoc
- Be conscious of backward compatibility -- breaking changes only in major versions
- Minimize dependencies -- each external dependency added is transitive to users
- Errors use clear custom exception/error types -- do not propagate internal errors as-is
- Example code and README always reflect the latest API
- Testing: 100% coverage of public API + backward compatibility tests
