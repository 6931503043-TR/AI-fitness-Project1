import js from "@eslint/js";
import { defineConfig } from "eslint/config";

export default defineConfig([
  {
    ignores: [
      "node_modules/**",
      "dist/**",
      "build/**",
      "coverage/**",
      ".dart_tool/**",
      ".flutter-plugins/**",
      ".flutter-plugins-dependencies",
    ],
  },

  js.configs.recommended,

  {
    files: ["**/*.{js,mjs,cjs,ts,tsx}"],

    linterOptions: {
      reportUnusedInlineConfigs: "error",
    },

    rules: {
      // Correctness
      "no-undef": "error",
      "no-unused-vars": [
        "error",
        {
          argsIgnorePattern: "^_",
          varsIgnorePattern: "^_",
        },
      ],

      // Avoid common footguns
      "eqeqeq": ["error", "always"],
      "no-constant-condition": "error",
      "no-debugger": "error",

      // Keep prototype code readable
      "complexity": ["warn", 12],
      "max-depth": ["warn", 4],
      "max-lines-per-function": [
        "warn",
        {
          max: 80,
          skipBlankLines: true,
          skipComments: true,
        },
      ],

      // Prefer immutable bindings where possible
      "prefer-const": "error",

      // Do not allow accidental console usage in application code.
      // Temporary debugging can use an explicit ESLint disable comment
      // with a reason.
      "no-console": "warn",
    },
  },

  // Tests are allowed to use console output when useful.
  {
    files: [
      "**/*.test.{js,mjs,cjs,ts,tsx}",
      "**/*.spec.{js,mjs,cjs,ts,tsx}",
      "tests/**/*.{js,mjs,cjs,ts,tsx}",
      "test/**/*.{js,mjs,cjs,ts,tsx}",
    ],
    rules: {
      "no-console": "off",
    },
  },
]);
