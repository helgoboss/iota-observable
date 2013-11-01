module.exports = function(grunt) {
  grunt.initConfig({
    coffee: {
      options: {
        bare: true
      },
      compile: {
        expand: true,
        flatten: true,
        src: ['src/*.coffee'],
        ext: '.js'
      }
    },
    simplemocha: {
      all: {
        src: 'test/**/*.coffee',
        options: {
          compilers: ['coffee:coffee-script']
        }
      }
    },
    umd: {
      all: {
        src: 'iota-observable.js',
        objectToExport: 'Observable',
        globalAlias: 'Observable'
      }
    }
  });
  
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-simple-mocha');
  grunt.loadNpmTasks('grunt-umd');
  
  grunt.registerTask('default', ['coffee', 'umd', 'simplemocha']);
};
