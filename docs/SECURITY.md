# OpenSuite — Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x     | ✅        |

## Reporting Vulnerabilities

Please report security vulnerabilities privately via GitHub Security Advisories or by emailing the maintainers. Do not open public issues for security concerns.

## Security Measures

### Data Storage
- All data stored locally on the user's device
- SQLite database with WAL mode for data integrity
- No data transmitted to external servers
- No telemetry or analytics collection in open-source builds

### Input Validation
- File name sanitization (removes dangerous characters, checks reserved names)
- File size limits (configurable, default 100MB)
- File type validation via extension and MIME type checking
- SQL parameterized queries to prevent injection

### Dependency Management
- All dependencies are open-source with permissive licenses
- Dependency versions pinned in pubspec.yaml
- GitHub Actions includes dependency audit step
- Regular dependency updates tracked via Dependabot (when configured)

### Code Quality
- Strict Dart analysis with `strict-casts`, `strict-inference`, `strict-raw-types`
- Comprehensive linter rules
- Automated formatting checks in CI
- No `eval()` or dynamic code execution

### Platform Security
- No unnecessary permissions requested on mobile platforms
- File access restricted to app sandbox and user-selected files
- Secure storage patterns for sensitive preferences

## Best Practices for Contributors

1. Never commit secrets, API keys, or credentials
2. Use parameterized queries for all database operations
3. Validate all user input before processing
4. Use the `AppError` system for structured error handling
5. Follow the principle of least privilege for platform permissions
6. Keep dependencies minimal and audited
