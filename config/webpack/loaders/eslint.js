module.exports = {
    enforce: `pre`,
    test: /\.(js|vue)$/i,
    exclude: [/node_modules/],
    loader: 'eslint-loader'
}