module.exports = {
  testEnvironment: 'node',
  // Roots for test files
  roots: ['<rootDir>/src'],
  // Regex for test files
  testRegex: '(/__tests__/.*|(\.|/)(test|spec))\\.jsx?$',
  // Test coverage
  collectCoverage: true,
  coverageDirectory: 'coverage',
  // You might want to ignore certain files from coverage
  coveragePathIgnorePatterns: [
    '/node_modules/',
    '/dist/'
  ]
};
