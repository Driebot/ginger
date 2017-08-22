'use strict';

var gulp = require('gulp'),
    sass = require('gulp-sass'),
    postcss = require('gulp-postcss'),
    autoprefixer = require('autoprefixer'),
    lost = require('lost'),
    globbing = require('gulp-css-globbing'),
    livereload = require('gulp-livereload');

var paths = {
    modulesSrc: [
        '../../modules/mod_ginger_foundation/lib/css/src',
    ],
    cssSource: 'lib/css/src/',
    cssDestination: 'lib/css/site/'
};

gulp.task('sass', function () {
    gulp.src(paths.cssSource + 'screen.scss')
        .pipe(globbing({ extensions: ['.scss'] }))
        .pipe(sass({outputStyle : 'compressed'}))
        .on('error', sass.logError)
        .pipe(postcss([
            lost(),
            autoprefixer('last 2 versions', 'ie > 7')
        ]))
        .pipe(gulp.dest(paths.cssDestination))
        .pipe(livereload());
});

gulp.task('sass:watch', function () {
    var modules = paths.modulesSrc.map(function(path) {
        return path + '/**/*.scss';
    });

    var watchPaths = [
        paths.cssSource + '/**/*.scss'
    ].concat(modules);

    gulp.watch(watchPaths, ['sass']);
});

gulp.task('default', ['sass', 'sass:watch']);
