# Changelog

## [0.4.0](https://github.com/hasansezertasan/copier-infra/compare/v0.3.0...v0.4.0) (2026-10-24)


### Features

* add a back reference to the template in the generated README ([#42](https://github.com/hasansezertasan/copier-infra/issues/42)) ([1970b3b](https://github.com/hasansezertasan/copier-infra/commit/1970b3b0752666d3d4e5fbe22caba27c31c74a48))
* leave the generated gitignore and editorconfig to the project ([#46](https://github.com/hasansezertasan/copier-infra/issues/46)) ([e600d4f](https://github.com/hasansezertasan/copier-infra/commit/e600d4f16a1963f0e0293930e7e7b29bf38cc1a8))


### Bug Fixes

* allow the configured S3-compatible endpoint in backend.tf ([#47](https://github.com/hasansezertasan/copier-infra/issues/47)) ([d432029](https://github.com/hasansezertasan/copier-infra/commit/d432029fcd0ebfd10b938d263bf9431189ef1e8c))
* stop claiming a versioned bucket for S3-compatible state stores ([#45](https://github.com/hasansezertasan/copier-infra/issues/45)) ([d689b74](https://github.com/hasansezertasan/copier-infra/commit/d689b74075dc603589e2ba85519dd91acfa3cc48))

## [0.3.0](https://github.com/hasansezertasan/copier-infra/compare/v0.2.0...v0.3.0) (2026-10-23)


### Features

* support S3-compatible state backends ([#39](https://github.com/hasansezertasan/copier-infra/issues/39)) ([619dc8c](https://github.com/hasansezertasan/copier-infra/commit/619dc8c7dd271ed8abadfb19826c8cadb27fd592))

## [0.2.0](https://github.com/hasansezertasan/copier-infra/compare/v0.1.0...v0.2.0) (2026-10-19)


### Features

* **template:** ask for state_region when the backend is gcs ([#29](https://github.com/hasansezertasan/copier-infra/issues/29)) ([fb132fa](https://github.com/hasansezertasan/copier-infra/commit/fb132fac5fd101d7cb1f8b4e2d2260b7d360ebe8))

## 0.1.0 (2026-10-18)


### ⚠ BREAKING CHANGES

* render the Config block and Decisions table in the README ([#25](https://github.com/hasansezertasan/copier-infra/issues/25))
* ask for the backend and point agents at infra-copilot ([#17](https://github.com/hasansezertasan/copier-infra/issues/17))
* convert infra-template into the copier-infra Copier template ([#9](https://github.com/hasansezertasan/copier-infra/issues/9))

### Features

* ask for the backend and point agents at infra-copilot ([#17](https://github.com/hasansezertasan/copier-infra/issues/17)) ([5a4acc2](https://github.com/hasansezertasan/copier-infra/commit/5a4acc2904a0248ae7fa9704b578910befd87bbf))
* convert infra-template into the copier-infra Copier template ([#9](https://github.com/hasansezertasan/copier-infra/issues/9)) ([cf06de1](https://github.com/hasansezertasan/copier-infra/commit/cf06de15b0c97557509a7ed53b9e05e386862035))
* render the Config block and Decisions table in the README ([#25](https://github.com/hasansezertasan/copier-infra/issues/25)) ([d67ae4f](https://github.com/hasansezertasan/copier-infra/commit/d67ae4f045d5bb700e27ffa9ad4a155d5a18bf38))
* scaffold infra-copilot template ([b5bb33e](https://github.com/hasansezertasan/copier-infra/commit/b5bb33e053140c53e10646999ec87fd6c664803e))
* scaffold infra-copilot template ([ce61ef9](https://github.com/hasansezertasan/copier-infra/commit/ce61ef9823c50ab076defeabbb764b0ebc95738e))


### Bug Fixes

* address template review feedback ([df7f182](https://github.com/hasansezertasan/copier-infra/commit/df7f1827844da3023fa2ca33faac108a600e6504))
* harden template validation ([8328f68](https://github.com/hasansezertasan/copier-infra/commit/8328f6889f600de1af742c632211f7a705d69c57))
* keep mise.toml at the root and declare backend: hcp ([#16](https://github.com/hasansezertasan/copier-infra/issues/16)) ([ebbbf36](https://github.com/hasansezertasan/copier-infra/commit/ebbbf36587a28c96cd7cecb48c6e1c1c40a95639))
* lock Linux provider checksums ([d2a62fb](https://github.com/hasansezertasan/copier-infra/commit/d2a62fb5974561a013e19a79e152cef5732b7e38))
