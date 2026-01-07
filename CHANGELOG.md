# VKDR Changelog


## v2.0.1 (2026-01-07)
* fix: correct log.sh path in generate-release-notes.sh (d34e59c)
* chore: bump version to 2.0.1-SNAPSHOT for V2 release (eac8561)
* chore: add update-tools-versions target and fix Makefile paths (81a9648)
* fix: update generate-tools-versions.sh and document in READMEs (a367254)
* docs: update READMEs for V2 formulas structure (8185c00)
* refactor(v2): remove legacy scripts/ directory, use formulas/ only (061241a)
* fix(tests): correct CLI flag names in BATS tests (f350c56)
* fix(tests): correct nginx install flag --default-ic (15cd793)
* fix(postgres): dropdb now actually drops database from PostgreSQL (49be41d)
* fix(tests): improve postgres tests for operator reconciliation (230a2b3)
* fix(tests): improve postgres test robustness (cfada1c)
* feat(v2): add infra lifecycle tests (up/down/start/stop) (b006ec2)
* feat(v2): add BATS tests for all formulas (e3da290)
* feat(v2): migrate all formulas to new structure (e3ee213)
* feat(v2): migrate kong formula to new structure (57efcc8)
* feat(v2): reorganize project structure with formulas/ and BATS testing (fe19506)
* add: CLAUDE.md for Claude Code guidance (b0a5f1e)

## v0.1.95 (2025-12-22)
* fix: github profile, add: --load-env option (a0db72d)

## v0.1.94 (2025-12-22)
* update devportal values for version 1.2.20+ (b6efbb1)

## v0.1.93 (2025-12-16)
* feat: nodeport-base (1021d75)

## v0.1.92 (2025-12-11)
* fix: sample org uids (08a1ee2)

## v0.1.91 (2025-12-11)
* add: openldap remove --delete (delete PVC option) (92eff2a)
* update tools versions (c3a96c4)

## v0.1.90 (2025-12-10)
* fix: updated gh action osx target archs (e44322f)

## v0.1.89 (2025-12-10)
* add: openldap tasks (50e36aa)

## v0.1.88 (2025-11-09)
* add: option --label to whoami (101fda7)

## v0.1.87 (2025-11-09)
* add: global --silent option (also passed down to scripts) (d4153b6)

## v0.1.86 (2025-11-09)
* add: infra getca command (4b1d7b1)

## v0.1.85 (2025-11-08)
* add: infra createToken clean plain output (506768d)

## v0.1.84 (2025-11-08)
* add: infra createToken (6972bbd)

## v0.1.83 (2025-11-04)
* added --label option to kong install (486daca)

## v0.1.82 (2025-11-03)
* keycloak operator fixes (8bc1370)

## v0.1.81 (2025-11-02)
* postgres dropdb and pingdb, keycloak operator based formulas (4516ead)

## v0.1.80 (2025-10-16)
* kong working with db operator (2f9b16f)
* fix: postgres wait (72b2efc)

## v0.1.79 (2025-10-16)
* postgres updated to CloudNativePG (CNPG) operator (54446a1)

## v0.1.78 (2025-09-18)
* included dicebear avatars im CSP rule (6d1aec3)

## v0.1.77 (2025-09-01)
* techdocs simple fix for target folder (e18fbfa)

## v0.1.76 (2025-08-25)
* local devportal install fixes (aa23a8e)

## v0.1.75 (2025-08-25)
* fix npmrc bug when using default registry (f415fd7)

## v0.1.74 (2025-08-25)
* removed '-march=native' (2d64b7f)

## v0.1.73 (2025-08-25)
* reverted back to spring boot 3.5.5 (8089cc4)

## v0.1.72 (2025-08-24)
* README translation, linux-arm now supported (9ecbb67)

## v0.1.71 (2025-08-22)
* update tools & docker check (9de3015)

## v0.1.70 (2025-08-22)
* devportal install --merge (f6d6d2f)

## v0.1.69 (2025-08-07)
* fixed DevPortal image tag (6d79278)

## v0.1.68 (2025-08-07)
* devportal install with npm registry argument (f834cf8)

## v0.1.67 (2025-07-22)
* local cluster visible as default (c6bbabd)

## v0.1.66 (2025-07-16)
* devportal install with better defaults + location parameter (239370b)

## v0.1.65 (2025-07-16)
* update devportal to 'next' chart (e2fc736)
* spring boot update (397d731)

## v0.1.64 (2025-06-06)
* 'make command' utility (e1d30f7)
* changelog formatting (9e0b71a)
* updated tools and windsurf rules (54eb576)

## v0.1.63 (2025-06-06)
* changelog formatting (1fd4925)
* removed unused import (1787588)
* upgraded spring boot to 3.5.0 (5c4e0dd)

## v0.1.62 (2025-06-06)
* 'vault generate-tls' command and optional vault tls for internal traffic (d479fe2)

## v0.1.61 (2025-05-30)
* fix nginx install bugs (d3e4baa)

## v0.1.60 (2025-05-29)
* workaround nginx progressDeadlineSeconds bug in chart default values (9434799)
* whoami ingress service fix in values (3aa66a1)
* ShellExecutor javadocs for sanity (3c8566b)

## v0.1.59 (2025-05-28)
* fixed 'traefik explain' command for good this time :) (384ce37)

## v0.1.58 (2025-05-28)
* fixes for 'traefik explain' command and glow download (4d9056c)

## v0.1.57 (2025-05-27)
* 'traefik explain' command (650c17f)

## v0.1.56 (2025-05-27)
* fixed release notes (22a1176)
* automated release notes (133aec7)
* traefik install/remove (429ddcf)

