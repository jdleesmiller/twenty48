var path = require('path')

if (process.env.BUNDLE_ANALYZER) {
  var BundleAnalyzerPlugin =
    require('webpack-bundle-analyzer').BundleAnalyzerPlugin
}

var LodashModuleReplacementPlugin = require('lodash-webpack-plugin')

require('webpack')

var outputFilename
if (process.env.NODE_ENV === 'production') {
  outputFilename = 'mdp_player.[hash].js'
} else {
  outputFilename = 'mdp_player.js'
}

var config = {
  mode: process.env.NODE_ENV || 'development',
  entry: './index',
  output: {
    path: path.resolve(__dirname, 'build'),
    filename: outputFilename
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /(node_modules|bower_components)/,
        use: {
          loader: 'babel-loader',
          options: {
            plugins: ['lodash']
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
