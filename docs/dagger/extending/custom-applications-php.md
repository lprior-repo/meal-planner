# PHP Custom Application

> **Note:** The Dagger PHP SDK requires [PHP 8.2 or later](https://www.php.net/downloads.php).

Install the Dagger PHP SDK in your project using `composer`:

```bash
composer require dagger/dagger
```

This example demonstrates how to test a PHP application against multiple PHP versions using the PHP SDK.

Clone an example project:

```bash
git clone https://github.com/slimphp/Slim-Skeleton.git
cd Slim-Skeleton
```

Create a new file named `test.php` in the project directory and add the following code to it.

```php
<?php

require('./vendor/autoload.php');

use function Dagger\dag;

function test() {
    // set PHP versions against which to test
    $phpVersions = ['8.2', '8.3'];

    // get reference to the local project
    $src = dag()
        ->host()
        ->directory('.');

    foreach($phpVersions as $version) {
        $php = dag()
            ->container()
            // get container with specified PHP version
            ->from("php:$version")
            // mount source code into image
            ->withDirectory('/src', $src)
            // set current working directory for next commands
            ->withWorkdir('/src')
            // install composer
            ->withExec(['apt-get', 'update'])
            ->withExec(['apt-get', 'install', '--yes', 'git-core', 'zip', 'curl'])
            ->withExec(['sh', '-c', 'curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer'])
            // install dependencies
            ->withExec(['composer', 'install'])
            // run tests
            ->withExec(['./vendor/bin/phpunit']);

        // execute
        echo "Starting tests for PHP $version...\n";
        echo $php->stdout();
        echo "Completed tests for PHP $version\n**********\n";
    }
}

test();
```

This PHP program imports the Dagger SDK and defines a function named `test()`. This `test()` function creates a Dagger client, which provides an interface to the Dagger API. It also defines the test matrix, consisting of PHP versions `8.2` to `8.4` and iterates over this matrix, downloading a PHP container image for each specified version and testing the source application in that version.

Run the PHP program by executing the command below from the project directory:

```bash
dagger run php test.php
```

The `dagger run` command executes the specified command in a Dagger session and displays live progress. The program tests the application against each version concurrently and displays the following final output:

```
Starting tests for PHP 8.2...
PHPUnit 9.6.22 by Sebastian Bergmann and contributors.

Warning:       Your XML configuration validates against a deprecated schema.
Suggestion:    Migrate your XML configuration using "--migrate-configuration"!

...................                                               19 / 19 (100%)

Time: 00:00.038, Memory: 12.00 MB

OK (19 tests, 37 assertions)

Completed tests for PHP 8.2
**********
Starting tests for PHP 8.3...
PHPUnit 9.6.22 by Sebastian Bergmann and contributors.

Warning:       Your XML configuration validates against a deprecated schema.
Suggestion:    Migrate your XML configuration using "--migrate-configuration"!

...................                                               19 / 19 (100%)

Time: 00:00.039, Memory: 12.00 MB

OK (19 tests, 37 assertions)

Completed tests for PHP 8.3
**********
```
