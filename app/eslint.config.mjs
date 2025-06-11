import eslint from '@eslint/js';

export default [
    // Global ignores: These patterns specify files/directories that ESLint should completely ignore.
    {
        ignores: [
            '**/node_modules/**', // Ignore Node.js dependency directory
            '**/dist/**',         // Ignore common build output directories
            '**/build/**',        // Ignore common build output directories
            '**/__tests__/**',    // Explicitly ignore your test files/directories
            // Add any other folders you want ESLint to completely skip here, e.g., '**/coverage/**'
        ],
    }
]