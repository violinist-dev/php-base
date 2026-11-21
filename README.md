# php-base

[![Test](https://github.com/violinist-dev/php-base/actions/workflows/test.yml/badge.svg)](https://github.com/violinist-dev/php-base/actions/workflows/test.yml)
[![violinist-dev/php-base/php-base](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2Feiriksm%2Fghcr-pulls%2Fmaster%2Fviolinist-dev-php-base.yml&query=$.human&label=docker%20pulls)](https://github.com/violinist-dev/php-base/pkgs/container/php-base)

Base image for all runners

## Building a PHP prerelease

To build an unreleased PHP version (alpha, beta or RC), add its minor version
(e.g. `"8.7"`) to the `php-version` matrix in both workflows and put the exact
Docker tag (e.g. `8.7.0alpha1`) in `unstable-tag`. Matrix entries matching that
tag are built from it instead of the stable image. Once the version is released,
empty `unstable-tag` again.
