// config/webpack/custom.js
const path = require("path");
const { VueLoaderPlugin } = require('vue-loader')
const webpack = require("webpack");

module.exports = {
  resolve: {
    extensions: ['.vue', '.mjs', '.js', '.sass', '.scss', '.css', '.module.sass', '.module.scss', '.module.css', '.png', '.svg', '.gif', '.jpeg', '.jpg'],
    alias: {
      'vue$': 'vue/dist/vue.esm.js', // necessary for vee-validate
      '@': path.resolve(__dirname, '..', '..', 'app/frontend/app'),
      '@components': path.resolve(__dirname, '..', '..', 'app/frontend/app/components'),
      '@assets': path.resolve(__dirname, '..', '..', 'app/frontend/app/assets'),
      '@pages': path.resolve(__dirname, '..', '..', 'app/frontend/app/pages'),
      '@helpers': path.resolve(__dirname, '..', '..', 'app/frontend/app/helpers'),
      '@mixins': path.resolve(__dirname, '..', '..', 'app/frontend/app/mixins'),
      '@directives': path.resolve(__dirname, '..', '..', 'app/frontend/app/directives'),
      '@store': path.resolve(__dirname, '..', '..', 'app/frontend/app/store'),
      '@models': path.resolve(__dirname, '..', '..', 'app/frontend/app/store/models'),
      '@modules': path.resolve(__dirname, '..', '..', 'app/frontend/app/store/modules'),
      '@utils': path.resolve(__dirname, '..', '..', 'app/frontend/app/utils'),
      '@data_transformers': path.resolve(__dirname, '..', '..', 'app/frontend/app/store/data_transformers'),
      '@uikit': path.resolve(__dirname, '..', '..', 'app/frontend/app/uikit'),
      '@plugins': path.resolve(__dirname, '..', '..', 'app/frontend/app/plugins'),
      '@locales': path.resolve(__dirname, '..', '..', 'config/locales/front_js')
    }
  },
  optimization: {
    minimize: process.env.NODE_ENV !== "development"
  },
  module: {
    rules: [
      // Vue loader
      {
        test: /\.vue(\.erb)?$/,
        use: [
          'vue-loader',
        ]
      },
      // Babel loader, will use your project’s .babelrc
      {
        test: /\.js?$/,
        exclude: /node_modules/,
        loader: 'babel-loader'
      },
      // Other loaders that are needed for your components
      {
        test: /\.scss$/,
        use: [
          'sass-loader'
        ]
      },
      {
        test: /\.css$/,
        exclude: /node_modules/,
        use: [
          'css-loader',
        ]
      },

    ]
  },
  plugins: [
    // add vue-loader plugin
    new VueLoaderPlugin(),
    new webpack.ProvidePlugin({
      process: "process/browser"
    })
  ]
}