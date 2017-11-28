const sh = require('shelljs')

// Create build dir
sh.mkdir('build')

// Export repository contents to build dir
sh.exec('git archive --format=tar --prefix=build/ HEAD | (tar xf -)')

// TODO: Copy non-managed files into CONTENT_DIR
// - Don't use wildcards here, copy them 1 by 1
// - Destination is always inside build directory
// Examples:
// sh.cp('-fr', 'web/app/plugins/some-plugin', 'build/web/app/plugins/')
// sh.cp('-fr', 'web/app/themes/some-theme', 'build/web/app/themes/')
// sh.cp('-fr', 'web/app/languages/*', 'build/web/app/languages/') // You may use wildcards for languages

// Move into build dir, fetch composer dependencies
sh.cd('build')
sh.exec('composer install -o')

// Move themes and plugins bundled with WP to CONTENT_DIR
// NOTE: If you don't need official themes and plugins, remove the following 3 lines
sh.mv('web/wp/wp-content/themes/*', 'web/app/themes/')
sh.mv('web/wp/wp-content/plugins/*', 'web/app/plugins/')
sh.rm('-f', 'web/app/plugins/hello.php')

// Create tarball
sh.exec('tar -zcf build.tar.gz *')
