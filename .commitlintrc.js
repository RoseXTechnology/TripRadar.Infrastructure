module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'build',
        'chore',
        'ci',
        'docs',
        'feat',
        'fix',
        'perf',
        'refactor',
        'revert',
        'style',
        'test',
        'infra',
        'security'
      ]
    ],
    'subject-case': [2, 'always', 'lower-case'],
    'subject-max-length': [2, 'always', 72],
    'body-max-line-length': [2, 'always', 200] // Increased from 100 to 200 to accommodate long URLs
  },
  ignores: [
    // Ignore Dependabot commits completely
    (commit) => {
      return commit.includes('dependabot[bot]') ||
             commit.includes('Signed-off-by: dependabot[bot]') ||
             commit.includes('dependabot-preview[bot]');
    },
    // Ignore merge commits
    (commit) => commit.includes('Merge') && commit.includes('branch'),
    // Ignore revert commits
    (commit) => commit.startsWith('Revert')
  ]
};
