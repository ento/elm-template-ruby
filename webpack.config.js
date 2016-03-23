const path = require('path');
const webpack = require('webpack');

const sourceRoot = path.join(__dirname, 'src');

module.exports = {
  context: sourceRoot,
  entry: './Native/Renderer.js',
  output: {
    filename: './assets/native_renderer.js',
    devtoolModuleFilenameTemplate: '[resourcePath]',
    devtoolFallbackModuleFilenameTemplate: '[resourcePath]?[hash]'
  },
  resolve: {
    extensions: ['', '.js'],
    modulesDirectories: ['./node_modules']
  }
};
