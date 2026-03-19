/** @type {import('jest').Config} */
module.exports = {
    testEnvironment: 'node',
    transform: {
        '^.+\\.ts$': ['ts-jest', {
            tsconfig: 'tsconfig.json',
            diagnostics: false,  // tsc handles diagnostics separately
        }],
    },
    moduleFileExtensions: ['ts', 'js', 'json'],
    testMatch: [
        '**/__tests__/**/*.test.js',
        '**/__tests__/**/*.test.ts',
    ],
};
