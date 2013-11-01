module.exports = function(grunt) {
  grunt.initConfig({
    coffee: {
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
    urequire: {
      umd: {
        template: 'UMDplain',
        path: '.',
        filez: 'iota-observable.js',
        forceOverwriteSources: true
      }
    }
  });
  
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-simple-mocha');
  grunt.loadNpmTasks('grunt-urequire');
  
  grunt.registerTask('default', ['coffee', 'urequire', 'simplemocha']);
};
