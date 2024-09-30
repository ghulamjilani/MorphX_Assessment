// config/webpack/webpack.config.js
// use the new NPM package name, `shakapacker`.
const { webpackConfig, merge } = require('shakapacker')
const customConfig = require('./custom_config')

module.exports = merge(webpackConfig, customConfig)
