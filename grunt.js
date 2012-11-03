module.exports = function(grunt) {
  grunt.initConfig({
    coffee: {
      compile: {
        options: {
          bare: true // because of "amdefine"
        },
        files: {
          "*.js": "src/*.coffee"
        }
      }
    },
    simplemocha: {
      all: {
        src: "test/**/*.coffee",
        options: {
          compilers: ["coffee:coffee-script"]
        }
      }
    }
  });
  
  grunt.loadNpmTasks("grunt-contrib-coffee");
  grunt.loadNpmTasks('grunt-simple-mocha');
  
  grunt.registerTask("default", "coffee simplemocha");
};
