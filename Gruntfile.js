module.exports = function(grunt) {
  grunt.initConfig({
    coffee: {
      compile: {
        options: {
          bare: true // because of 'amdefine'
        },
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
    }
  });
  
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-simple-mocha');
  
  grunt.registerTask('default', ['coffee', 'simplemocha']);
};
