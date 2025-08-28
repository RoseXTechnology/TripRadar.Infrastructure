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
    'subject-case': [0], // Disable case checking
    'subject-max-length': [2, 'always', 100], // Allow longer subjects
    'body-max-line-length': [0], // Disable body line length checking
    'footer-max-line-length': [0] // Disable footer line length checking
  }
};
