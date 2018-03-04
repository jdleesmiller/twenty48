var path = require('path')

if (process.env.BUNDLE_ANALYZER) {
  var BundleAnalyzerPlugin =
    require('webpack-bundle-analyzer').BundleAnalyzerPlugin
}

var LodashModuleReplacementPlugin = require('lodash-webpack-plugin')

require('webpack')

var config = {
  entry: './index',
  output: {
    path: path.resolve(__dirname, 'build'),
    filename: 'bundle.js'
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /(node_modules|bower_components)/,
        use: {
          loader: 'babel-loader',
          options: {
            plugins: ['lodash'],
            presets: ['env']
          }
        }
      }
    ]
  },
  plugins: [
    new LodashModuleReplacementPlugin()
  ],
  stats: {
    colors: true
  },
  devtool: 'source-map'
}

if (BundleAnalyzerPlugin) {
  config.plugins.push(new BundleAnalyzerPlugin())
}

module.exports = config
