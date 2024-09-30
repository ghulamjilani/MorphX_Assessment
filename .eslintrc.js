module.exports = {
  env: {
    browser: true,
    es2021: true
  },
  extends: [
    'eslint:recommended',
    'plugin:vue/recommended'
  ],
  parserOptions: {
    ecmaVersion: 12,
    sourceType: 'module',
    parser: '@babel/eslint-parser'
  },
  plugins: [
    'vue'
  ],
  rules: {
    // eslint:recommended - https://eslint.org/docs/rules/
    'semi': ['error', 'never'],
    'comma-dangle': ['error', 'never'],
    // plugin:vue/recommended
    "vue/max-attributes-per-line": ["error", {
      "singleline": 1,
      "multiline": 1
    }],
    "vue/html-indent": ["error", 4, {
      "attribute": 1,
      "baseIndent": 1,
      "closeBracket": 0,
      "alignAttributesVertically": true,
      "ignores": []
    }],
    "vue/html-closing-bracket-newline": ["error", {
      "singleline": "never",
      "multiline": "never"
    }],
    'vue/order-in-components': 'error',
    // TODO: enable
    'vue/require-prop-types': 'off',
    'vue/require-default-prop': 'off',
    'vue/no-v-html': 'off'
    // 'vue/prop-name-casing': 'error'
  }
}
