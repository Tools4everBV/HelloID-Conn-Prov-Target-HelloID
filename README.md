
# HelloID-Conn-Prov-Target-HelloID

<!--
** for extra information about alert syntax please refer to [Alerts](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#alerts)
-->

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="https://github.com/Tools4everBV/HelloID-Conn-Prov-Target-HelloID/blob/main/Logo.png?raw=true">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-HelloID](#helloid-conn-prov-target-helloid)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Supported features](#supported-features)
  - [Getting started](#getting-started)
    - [HelloID Icon URL](#helloid-icon-url)
    - [Requirements](#requirements)
    - [Connection settings](#connection-settings)
    - [Correlation configuration](#correlation-configuration)
    - [Field mapping](#field-mapping)
    - [Account Reference](#account-reference)
  - [Remarks](#remarks)
    - [Product assignments](#product-assignments)
  - [Development resources](#development-resources)
    - [API endpoints](#api-endpoints)
    - [API documentation](#api-documentation)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-HelloID_ is a _target_ connector. _HelloID_ provides a set of REST APIs that allow you to programmatically interact with its data.

## Supported features

The following features are available:

| Feature                                   | Supported | Actions                                 | Remarks           |
| ----------------------------------------- | --------- | --------------------------------------- | ----------------- |
| **Account Lifecycle**                     | ✅         | Create, Update, Enable, Disable, Delete |                   |
| **Permissions**                           | ✅         | Retrieve, Grant, Revoke                 | Static or Dynamic |
| **Resources**                             | ✅         | Retrieve, Create                        | Groups only       |
| **Entitlement Import: Accounts**          | ✅         | -                                       |                   |
| **Entitlement Import: Permissions**       | ✅         | -                                       | Groups, Products  |
| **Governance Reconciliation Resolutions** | ✅         | -                                       |                   |

<!--
Example
### ⚠️ Governance Reconciliation Resolutions
Governance reconciliation is supported for reporting purposes.
Resolutions are not possible because...
-->

## Getting started

### HelloID Icon URL
URL of the icon used for the HelloID Provisioning target system.
```
https://raw.githubusercontent.com/Tools4everBV/HelloID-Conn-Prov-Target-HelloID/refs/heads/main/Icon.png
```

### Requirements

- _HelloID_ Provisioning agent (cloud or on-prem).
- _HelloID_ environment.
- Access to the _HelloID_ API.
  - API Key
  - API Secret

### Connection settings

The following settings are required to connect to the API.

| Setting        | Description                                                                                                                        | Mandatory |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------- | --------- |
| Base URL       | The URL to the API                                                                                                                 | Yes       |
| Api key        | The key to connect to the API                                                                                                      | Yes       |
| Api secret     | The secret to connect to the API                                                                                                   | Yes       |
| Set manager    | As we use the AccountReference of the manager for this, HelloID has to have granted the Account entitlement for the manager first. | No        |
| UpdateUserName | When toggled, the username will be updated                                                                                         | No        |

### Correlation configuration

The correlation configuration is used to specify which properties will be used to match an existing account within _HelloID_ to a person in _HelloID_.

| Setting                   | Value                                |
| ------------------------- | ------------------------------------ |
| Enable correlation        | `True`                               |
| Person correlation field  | `Accounts.EntraID.userPrincipalName` |
| Account correlation field | `UserName`                           |

> [!TIP]
> _For more information on correlation, please refer to our correlation [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html) pages_.

### Field mapping

The field mapping can be imported by using the _fieldMapping.json_ file.

### Account Reference

The account reference is populated with the property `userGUID` from _HelloID_.

## Remarks

### Product assignments
- The product grant script only requests the product in case it has not been assigned for the account yet.
- The product revoke script revokes all assignments for the requested product.

## Development resources

### API endpoints

The following endpoints are used by the connector

| Endpoint                                       | HTTP Method | Description                                   |
| ---------------------------------------------- | ----------- | --------------------------------------------- |
| /api/v1/users                                  | GET, POST   | Retrieve and create user information          |
| /api/v1/users/{UserId}                         | GET, PUT    | Retrieve and update specific user information |
| /api/v1/users/{UserId}                         | DELETE      | Delete a user                                 |
| /api/v1/groups                                 | GET, POST   | Retrieve and create groups                    |
| /api/v1/groups/{GroupId}                       | GET         | Retrieve specific group                       |
| /api/v1/users/{UserId}/groups                  | POST        | Grant group to user                           |
| /api/v1/{UserId}/groups/{GroupId}              | DELETE      | Revoke group from user                        |
| /api/v1/products                               | GET         | Retrieve products                             |
| /api/v1/selfservice/products/request           | POST        | Request product for user                      |
| /api/v1/product-assignment                     | GET         | Retrieve product assignments                  |
| /api/v1/product-assignment/by-user/{Id}        | GET         | Retrieve product assignments by user          |
| /api/v1/product-assignment/unassign/by-product | POST        | Unassign product from user                    |

### API documentation

- [Generate an API key](https://docs.helloid.com/en/api/generate-an-api-key.html)
- [HelloID API documentation](https://apidocs.helloid.com/docs/helloid/)

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/

