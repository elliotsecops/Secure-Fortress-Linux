# Contributing to Fortress Linux

Thank you for your interest in contributing to Fortress Linux! This document provides guidelines and instructions for contributing to the project.

## 🤝 Code of Conduct

### Our Pledge
We as members, contributors, and leaders pledge to make participation in our community a harassment-free experience for everyone, regardless of age, body size, visible or invisible disability, ethnicity, sex characteristics, gender identity and expression, level of experience, education, socio-economic status, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards
Examples of behavior that contributes to creating a positive environment include:
- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

Examples of unacceptable behavior include:
- Trolling, insulting/derogatory comments, and personal or political attacks
- Public or private harassment
- Publishing others' private information, such as a physical or electronic address, without explicit permission
- Other conduct which could reasonably be considered inappropriate in a professional setting

## 🚀 Getting Started

### Prerequisites
- Git installed on your system
- GitHub account
- Basic knowledge of Bash, Ansible, and Linux system administration
- Understanding of security best practices

### Development Setup
1. **Fork the Repository**
   ```bash
   # Fork the repository on GitHub first
   git clone https://github.com/your-username/fortress-linux.git
   cd fortress-linux
   ```

2. **Create Development Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Set Up Development Environment**
   ```bash
   # Install Ansible if not already installed
   sudo apt install ansible -y

   # Install Python dependencies
   pip install -r requirements.txt
   ```

## 📝 Contribution Guidelines

### Types of Contributions
- **Bug fixes**: Address security vulnerabilities or functionality issues
- **Feature enhancements**: Add new security hardening features
- **Documentation**: Improve README, guides, or inline comments
- **Test improvements**: Add or enhance testing procedures
- **Performance optimizations**: Improve script efficiency

### Security-First Approach
All contributions must follow security best practices:
- **No hardcoded credentials**: Use environment variables or configuration files
- **Input validation**: Validate all user inputs and external data
- **Error handling**: Implement proper error handling without exposing sensitive information
- **Least privilege**: Scripts should run with minimum necessary privileges
- **Audit trails**: Include logging for security-relevant operations

### Code Standards

#### Bash Scripts
- Use `#!/bin/bash` shebang
- Follow ShellCheck guidelines
- Use `set -euo pipefail` for error handling
- Comment security-critical operations
- Quote variables to prevent word splitting

#### Ansible Playbooks
- Follow Ansible best practices
- Use meaningful task names
- Include proper error handling
- Document variable usage
- Use idempotent operations

#### General Guidelines
- **Indentation**: 2 spaces for YAML, 4 spaces for Python/Bash
- **Comments**: Explain security decisions and complex logic
- **Variables**: Use descriptive names
- **Error messages**: Provide clear, actionable error messages

## 🧪 Testing Requirements

### Before Submitting
1. **Test in Development Environment**
   ```bash
   # Syntax check for bash scripts
   bash -n scripts/linux_hardening.sh

   # Syntax check for Ansible playbooks
   ansible-playbook --syntax-check playbooks/playbook_hardening.yml
   ```

2. **Test Functionality**
   - Run scripts in a test VM or container
   - Verify all security hardening measures work as expected
   - Test rollback procedures
   - Ensure no breaking changes to existing functionality

3. **Security Testing**
   - Review code for security vulnerabilities
   - Test with various user permission levels
   - Verify file permissions and access controls
   - Test error handling scenarios

### Test Environment Setup
```bash
# Create test environment
docker run -it ubuntu:latest /bin/bash
# Apply hardening and verify results
```

## 📋 Pull Request Process

### 1. Create Pull Request
- Use clear, descriptive title
- Reference relevant issues (e.g., "Fixes #123")
- Provide detailed description of changes
- Include testing procedures and results

### 2. PR Description Template
```markdown
## Summary
[Brief description of changes]

## Changes Made
- [ ] Feature enhancement
- [ ] Bug fix
- [ ] Documentation update
- [ ] Security improvement

## Testing
- [ ] Tested in development environment
- [ ] Tested with various configurations
- [ ] Security review completed
- [ ] No breaking changes introduced

## Related Issues
Closes #issue-number
```

### 3. Review Process
- Automated checks (linting, syntax validation)
- Security review by maintainers
- Code review for best practices
- Testing verification by maintainers

### 4. Merge Requirements
- All automated checks must pass
- At least one maintainer approval required
- Security-related changes require additional review
- Documentation must be updated for new features

## 🔍 Issue Reporting

### Bug Reports
When reporting bugs, please include:
- **Environment**: OS version, distribution, architecture
- **Steps to reproduce**: Detailed reproduction steps
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Error messages**: Complete error output
- **Logs**: Relevant log entries

### Feature Requests
For new feature requests, provide:
- **Problem statement**: What problem does this solve?
- **Proposed solution**: How should it work?
- **Use cases**: Specific scenarios where this would be useful
- **Alternatives**: Other approaches considered

### Security Vulnerabilities
For security vulnerabilities, please:
- **Do not** create public issues
- **Email**: security@example.com with vulnerability details
- **Include**: Steps to reproduce, potential impact, suggested fix
- **Allow time**: Give maintainers time to address before disclosure

## 📚 Documentation Standards

### README Updates
- Update installation instructions for new features
- Add configuration examples
- Include troubleshooting steps
- Update version compatibility information

### Inline Documentation
- Comment complex security logic
- Document function parameters and return values
- Include examples for configuration options
- Explain security trade-offs and decisions

## 🏷️ Version Control

### Commit Messages
Use conventional commit format:
```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code formatting
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Maintenance tasks

**Examples:**
```
feat(security): add password policy enforcement
fix(firewall): resolve ufw configuration issue
docs(readme): update installation instructions
```

### Branch Naming
- `feature/feature-name`: New features
- `fix/issue-description`: Bug fixes
- `docs/documentation-update`: Documentation changes
- `security/vulnerability-fix`: Security patches

## 🎯 Community Guidelines

### Communication
- Be respectful and professional
- Focus on technical discussions
- Provide constructive feedback
- Help new contributors

### Recognition
- Contributions will be acknowledged in release notes
- Significant contributors may be invited as maintainers
- Security researchers will be credited for vulnerability reports

## 📞 Getting Help

### Resources
- **Documentation**: README.md and inline comments
- **Issues**: Search existing issues before creating new ones
- **Discussions**: Join community discussions
- **Email**: Contact maintainers for private questions

### Support Channels
- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For general questions
- **Security Issues**: security@example.com
- **Maintainer Contact**: Check individual profiles

## 🏆 Recognition

### Contributor Credits
- All contributors are credited in the repository
- Significant contributions may be added to maintainers team
- Security researchers will be acknowledged in security advisories

### Project Rewards
- Contributors may receive project swag
- Regular contributors may be invited to join the core team
- Security researchers may be eligible for bug bounty programs

---

Thank you for contributing to Fortress Linux and helping make Linux systems more secure! 🛡️