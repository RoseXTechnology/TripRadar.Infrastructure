// Test script to verify commitlint configuration
const config = require('./.commitlintrc.js');

const dependabotCommit = `ci(deps): bump wagoid/commitlint-github-action from 5 to 6

Bumps [wagoid/commitlint-github-action](https://github.com/wagoid/commitlint-github-action) from 5 to 6.
- [Changelog](https://github.com/wagoid/commitlint-github-action/blob/master/CHANGELOG.md)
- [Commits](https://github.com/wagoid/commitlint-github-action/compare/v5...v6)

---
updated-dependencies:
- dependency-name: wagoid/commitlint-github-action
  dependency-version: '6'
  dependency-type: direct:production
  update-type: version-update:semver-major
...

Signed-off-by: dependabot[bot] <support@github.com>`;

const regularCommit = `feat: add new authentication feature

This commit adds a new authentication feature with JWT tokens.
- Implements user login/logout
- Adds password reset functionality
- Includes proper error handling`;

console.log('🧪 Testing Commitlint Configuration\n');

console.log('1. Dependabot Commit Test:');
console.log('Should be ignored:', config.ignores.some(ignore => ignore(dependabotCommit)));
console.log('Contains dependabot signature:', dependabotCommit.includes('dependabot[bot]'));

console.log('\n2. Regular Commit Test:');
console.log('Should NOT be ignored:', !config.ignores.some(ignore => ignore(regularCommit)));
console.log('Contains dependabot signature:', regularCommit.includes('dependabot[bot]'));

console.log('\n3. Line Length Check:');
console.log('Max body line length:', config.rules['body-max-line-length'][2]);
const longLine = dependabotCommit.split('\n').find(line => line.length > 100);
if (longLine) {
  console.log('Long line found:', longLine.length, 'characters');
  console.log('Line content:', longLine.substring(0, 80) + '...');
}

console.log('\n✅ Configuration loaded successfully!');
