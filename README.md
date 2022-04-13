| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.       |
<br />

<p align="center">
  <img src="https://www.tools4ever.nl/Static/images/helloid/ico-%20HelloID%20icon%20[RGB]@128.png">
</p>

## Versioning
| Version | Description | Date |
| - | - | - |
| 1.0.0   | Initial release | 2020/06/10  |
| 1.1.0   | Updated with new logging and the request of a Self Service Product as entitlements | 2022/04/13  |

<!-- TABLE OF CONTENTS -->
## Table of Contents
- [Table of Contents](#table-of-contents)
- [Requirements](#requirements) 
- [Introduction](#introduction)
- [Getting Started](#getting-started)
  - [Connection settings](#connection-settings)
- [Getting help](#getting-help)
- [HelloID Docs](#helloid-docs)

## Requirements
- HelloID environment
- API key and secret

## Introduction
The interface to communicate with HelloID is through a set of API endpoints, which are accessible with the use of the HelloID API Key and Secret. Warning: The API is very powerful, therefore the API key and secret must be kept private and be used with care.
Please see the following page from the HelloID Docs for more information.

[How to create and Manage API Keys](https://docs.helloid.com/hc/en-us/articles/360002741753-How-to-Create-and-Manage-API-Keys)

<!-- GETTING STARTED -->
## Getting Started

By using this connector you will have the ability to create, update and delete accounts in HelloID.
This connector will also prove you with the ability to assign or revoke groupmemberships as entitlements.
Additionally, there now is support to request a self service product as entitlements.
  >__Currently, only the request of self service products is supported, we cannot return a self service product yet__

### Connection settings
The following settings are required to connect.

| Setting     | Description |
| ------------ | ----------- |
| Portal Base URL | The base URL of the portal of the HelloID environment |
| API Key | The API key of the HelloID environment |
| API Secret | The API secret of the HelloID environment |
| Restore soft deleted users | Restore soft deleted users on update actions (create (correlate), update, enable, disable) |
| Update on correlation | Update user account with mapped attributes upon correlation |
| Overwrite password on update | Overwrite the current password when updating the user account |

## Getting help
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/360012518799-How-to-add-a-target-system) pages_

> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com/forum/helloid-connectors/provisioning/830-helloid-provisioning-helloid-conn-prov-target-helloid)_

## HelloID Docs
The official HelloID documentation can be found at: https://docs.helloid.com/