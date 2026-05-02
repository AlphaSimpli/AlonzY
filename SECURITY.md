# Security Guidelines

## Overview

This document outlines the security measures in place for this Flutter application and best practices for maintaining security.

## Credential Management

### Environment Variables
- **Never commit `.env` files** to version control
- Use `.env.example` as a template for required variables
- Load credentials at runtime using `flutter_dotenv`
- Credentials are loaded from `lib/main.dart` during initialization

### File Patterns in `.gitignore`
```
.env
.env.local
.env.*.local
```

## Supabase Security

### API Keys
- The **anonymous key** (`SUPABASE_ANON_KEY`) is safe to expose in client-side code
- Never expose the **service role key** in client applications
- Rotate keys periodically as a security best practice

### Row-Level Security (RLS)
- Enable RLS on all Supabase tables
- Define appropriate policies for read/write access
- Test RLS policies thoroughly before production

### Authentication
- Use strong password requirements
- Implement email verification flows
- Handle session tokens securely
- Never log credentials

## Platform-Specific Security

### iOS
- Ensure Location permissions are properly requested
- Use HTTPS for all API calls
- Keep CocoaPods dependencies updated

### Android
- Enable network security configuration
- Request runtime permissions appropriately
- Verify Google Play Signing is configured

## Google Maps API Key Security

### Handling API Keys
- Use separate keys for development and production
- Restrict API key usage in Google Cloud Console
- Regenerate keys if compromised

### Platform-Specific Configuration
- **iOS**: Key is added in native configuration
- **Android**: Key is added in `AndroidManifest.xml`
- Never hardcode API keys in Dart code

## Data Handling

### Sensitive Information
- Avoid logging sensitive user data
- Clear sensitive data from memory when no longer needed
- Use HTTPS for all network communications
- Validate and sanitize all user inputs

### Local Storage
- Use secure storage for tokens if implementing local persistence
- Clear app cache when user logs out
- Never store passwords locally

## Deployment Security

### Before Publishing

1. **Rotate Credentials**
   - Generate new Supabase keys for production
   - Update all API keys to production versions

2. **Code Review**
   - Audit code for hardcoded secrets
   - Review all API endpoints
   - Check for debug logging statements

3. **Testing**
   - Test authentication flows
   - Verify RLS policies are working
   - Test error handling for failed requests

### Post-Deployment

1. **Monitor**
   - Watch for unusual API usage patterns
   - Monitor error rates and logs
   - Track authentication failures

2. **Maintenance**
   - Keep dependencies updated
   - Apply security patches promptly
   - Review and update security policies regularly

## Incident Response

If credentials are compromised:

1. **Immediately rotate** all exposed keys in Supabase
2. **Revert** the commit containing sensitive data (force push to origin)
3. **Scan** git history for other exposed credentials
4. **Notify users** if user data was potentially affected

## Git History Cleanup

If credentials were accidentally committed:

```bash
# Using BFG Repo-Cleaner (recommended for large repos)
bfg --replace-all 'exposed_key' --no-blob-protection

# Or git-filter-branch (for smaller repos)
git filter-branch --tree-filter 'rm -f .env' HEAD
```

## Recommended Tools

- **bfg**: BFG Repo-Cleaner for removing sensitive data from history
- **detect-secrets**: Pre-commit hook to detect accidental secrets
- **git-secrets**: AWS tool to prevent secrets in Git repos

## Additional Resources

- [Supabase Security Documentation](https://supabase.com/docs/guides/platform/security)
- [Flutter Security Best Practices](https://flutter.dev/docs/development/security)
- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
- [Google Maps Security Best Practices](https://developers.google.com/maps/documentation/security/best-practices)

## Questions or Concerns?

If you identify a security issue, please report it responsibly to the project maintainers.

---

**Last Updated**: May 1, 2026
