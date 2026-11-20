module.exports = {
  rootDir: '.',
  roots: ['<rootDir>/src'],
  testRegex: '.*\\.spec\\.ts$',
  testEnvironment: 'node',
  transform: { '^.+\\.(t|j)s$': 'ts-jest' },
  moduleFileExtensions: ['js', 'json', 'ts'],
};
