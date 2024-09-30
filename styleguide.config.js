const { VueLoaderPlugin } = require('vue-loader')

module.exports = {
  components: 'app/frontend/app/uikit/**/[A-Z]*.vue',
  // ignore: ['app/frontend/app/uikit/docs/**/[A-Z]*.vue'],
  copyCodeButton: true,
  webpackConfig: {
    module: {
      rules: [
        // Vue loader
        {
          test: /\.vue$/,
          exclude: /node_modules/,
          loader: 'vue-loader'
        },
        // Babel loader, will use your project’s .babelrc
        {
          test: /\.js?$/,
          exclude: /node_modules/,
          loader: 'babel-loader'
        },
        // Other loaders that are needed for your components
				{
					test: /\.(css?|scss)(\?.*)?$/,
					loader: 'style-loader!css-loader!sass-loader'
				}
      ]
    },
    plugins: [
      // add vue-loader plugin
      new VueLoaderPlugin()
    ]
  }
}