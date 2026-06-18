# Change Log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [2.2.0] - 2026-06-03

### Added

- Added GitHub workflows for creating releases and verifying changelog updates
- Added correlateOnly scripts for correlation-only scenarios (configuration, create, and fieldMapping)

### Changed

- Refactored `permissions/groups/permissions.ps1` with streamlined workflow and enhanced error handling
- Refactored `permissions/groups/grantPermission.ps1` with improved correlation mapping and error handling
- Refactored `permissions/groups/revokePermission.ps1` with improved correlation mapping and error handling
- Renamed `permissions/groups/import.ps1` to `permissions/groups/importPermissions.ps1` and refactored with improved error handling
- Refactored `import.ps1` (main import script) with improved structure

### Fixed

- Removed `TimeoutSec` parameter from all scripts better compatibility
- Fixed `permissions/groups/importPermissions.ps1` to filter for local groups only

## [2.1.0] - 2026-05-28

### Added

- Added `lastName` field to field mapping configuration

### Changed

- Updated references from AzureAD to EntraID and logo
- Updated README.md with improved documentation

### Fixed

- Fixed empty correlation value returned success issue
- Fixed UrlEncode for correlationValue (username)
- Fixed support for reconciliation action in disable

## [2.0.0] - 2024-06-03

This is a major release featuring a complete migration to PowerShell V2 connector architecture with full rework of all scripts.

### Added

- Added check if fields are in account mapping
- Added proper manager account reference handling
- Added headers creation at script start
- Added comprehensive group and product permission management

### Changed

- Full code update and migration to PS V2 connector architecture
- Initial release of PS V2 connector with complete script rework
- Changed `$actionContext.References.ManagerAccount.userGUID` to `$actionContext.References.ManagerAccount`
- Moved creation of headers to start of scripts
- Replaced guid with systemname and corrected contactEmail mapping
- Updated icon reference in README

## [1.0.0] - 2023-04-12

This is the first official versioned release of HelloID-Conn-Prov-Target-HelloID.

### Added

- Added version information to the connector

## [0.9.0] - 2022-04-15

### Added

- Added dynamic permission example for departments
- Added resource creation example for departments

### Changed

- Updated with manager, department and title fields
- Updated with correct (optionally) exportdata

### Fixed

- Corrected revoke URI for permission management

## [0.8.0] - 2022-04-13

### Added

- Added Self Service Product request as entitlements
- Updated with new logging implementation

### Removed

- Removed unnecessary asset files

## [0.5.0] - 2022-01-17

### Changed

- Updated README.md with improved documentation

## [0.4.0] - 2021-04-27

### Changed

- Updated README.md

## [0.3.0] - 2020-12-09

### Added

- Added correlation functionality

### Changed

- Updated with the use of configuration.json
- Updated README.md

### Fixed

- Fixed issue with logging (Response Stream) which would fail when running on the Cloud agent

## [0.2.0] - 2020-08-18

### Added

- Created initial `revokePermission.ps1` script
- Created initial `grantPermission.ps1` script  
- Created initial `entitlements.ps1` script

### Changed

- Updated README.md

## [0.1.0] - 2020-07-10

Initial release of HelloID-Conn-Prov-Target-HelloID connector.

### Added

- Initial commit with basic connector functionality
- Basic lifecycle management (create, update, enable, disable, delete)
- Initial README documentation
