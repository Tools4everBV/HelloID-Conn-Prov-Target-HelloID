
# HelloID-Conn-Prov-Target-HelloID

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="https://github.com/Tools4everBV/HelloID-Conn-Prov-Target-HelloID/blob/master/Logo.png?raw=true">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-HelloID](#helloid-conn-prov-target-helloid)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Getting started](#getting-started)
    - [HelloID Icon URL](#helloid-icon-url)
    - [Provisioning PowerShell V2 connector](#provisioning-powershell-v2-connector)
      - [Correlation configuration](#correlation-configuration)
      - [Field mapping](#field-mapping)
    - [Connection settings](#connection-settings)
    - [Prerequisites](#prerequisites)
    - [Remarks](#remarks)
  - [Setup the connector](#setup-the-connector)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-HelloID_ is a _target_ connector. _HelloID_ provides a set of REST API's that allow you to programmatically interact with its data. The HelloID connector uses the API endpoints listed in the table below.

| Endpoint                                                                                                                    | Description                         |
| --------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- |
| [/api/v1/users/{UserId}](https://apidocs.helloid.com/docs/helloid/562f51f234ff9-get-a-user)                                 | Get specific user account (GET)     |
| [/api/v1/users/](https://apidocs.helloid.com/docs/helloid/7d9592b2cfeed-add-a-user)                                         | Create user accounts (POST)         |
| [/api/v1/users/{UserId}](https://apidocs.helloid.com/docs/helloid/b432862fd92c6-update-a-user)                              | Update user accounts (PUT)          |
| [/api/v1/users/{UserId}](https://apidocs.helloid.com/docs/helloid/9d294ac38808f-delete-a-user)                              | Delete user accounts (DELETE)       |
| [/api/v1/groups](https://apidocs.helloid.com/docs/helloid/15f7f74779d57-get-all-groups)                                     | Get all groups (GET)                |
| [/api/v1/users/{UserId}/groups](https://apidocs.helloid.com/docs/helloid/575c5cde6e378-link-a-user-to-a-group)              | Grant group to user (POST)          |
| [/api/v1/{UserId}/groups/{GroupId}](https://apidocs.helloid.com/docs/helloid/403a836a09d77-unlink-a-user-from-a-group)      | Revoke group from user (DELETE)     |
| [/api/v1/groups](https://tools4ever.stoplight.io/docs/helloid/0b84c01989115-add-a-group)                                    | Create groups (POST)                |
| [/api/v1/selfservice/products](https://apidocs.helloid.com/docs/helloid/ddbf642b3d115-get-all-products)                     | Get all products (GET)              |
| [/api/v1/selfservice/products/request](https://apidocs.helloid.com/docs/helloid/5fff6c1a37337-request-a-product-for-a-user) | Request a product for a user (POST) |

The following lifecycle actions are available:

| Action                        | Description                                                                                          |
| ----------------------------- | ---------------------------------------------------------------------------------------------------- |
| create.ps1                    | Create or correlate to an account                                                                    |
| delete.ps1                    | Delete an account                                                                                    |
| disable.ps1                   | Disable an account                                                                                   |
| enable.ps1                    | Enable an account                                                                                    |
| update.ps1                    | Update an account                                                                                    |
| permissions.groups.ps1        | List groups as permissions                                                                           |
| grantPermission.groups.ps1    | Grant groupmembership to an account                                                                  |
| revokePermission.groups.ps1   | Revoke groupmembership from an account                                                               |
| permissions.products.ps1      | List products as permissions                                                                         |
| grantPermission.products.ps1  | Request product for an account                                                                       |
| revokePermission.products.ps1 | **Note:** there is no functionality to "unrequest" a product, therefore this is just an empty script |
| resources.groups.ps1          | Create group based on HR data                                                                        |
| configuration.json            | Default _configuration.json_                                                                         |
| fieldMapping.json             | Default _fieldMapping.json_                                                                          |

## Getting started
By using this connector you will have the ability to seamlessly create and manage user accounts and groups in HelloID. Additionally, you can request products for users, enhancing your workflow. It's important to note that at this time, there isn't a feature to "unrequest" a product.

Connecting to HelloID is straightforward. Simply utilize the API Key and API Secret pair.
For further details, refer to the following pages in the HelloID Docs:

[Generate an API key](https://docs.helloid.com/en/api/generate-an-api-key.html).
[API docs](https://apidocs.helloid.com/docs/helloid/)

### HelloID Icon URL
URL of the icon used for the HelloID Provisioning target system.

```
https://raw.githubusercontent.com/Tools4everBV/HelloID-Conn-Prov-Target-HelloID/refs/heads/main/Icon.png
```

### Provisioning PowerShell V2 connector

#### Correlation configuration

The correlation configuration is used to specify which properties will be used to match an existing account within _HelloID_ to a person in _HelloID_.

To properly setup the correlation:

1. Open the `Correlation` tab.

2. Specify the following configuration:

    | Setting                   | Value      |
    | ------------------------- | ---------- |
    | Enable correlation        | `True`     |
    | Person correlation field  | ``         |
    | Account correlation field | `UserName` |

> [!TIP]
> _For more information on correlation, please refer to our correlation [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html) pages_.

#### Field mapping

The field mapping can be imported by using the _fieldMapping.json_ file.

### Connection settings

The following settings are required to connect to the API.

| Setting        | Description                                                                                                                        | Mandatory |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------- | --------- |
| Base URL       | The URL to the API                                                                                                                 | Yes       |
| Api key        | The key to connect to the API                                                                                                      | Yes       |
| Api secret     | The secret to connect to the API                                                                                                   | Yes       |
| Set manager    | As we use the AccountReference of the manager for this, HelloID has to have granted the Account entitlement for the manager first. | No        |
| UpdateUserName | When toggled, the username will be updated                                                                                         | No        |
| IsDebug        | When toggled, extra logging is shown. Note that this is only meant for debugging, please switch this off when in production.       | No        |

### Prerequisites
- [ ] _HelloID_ Provisioning agent (cloud or on-prem).
- [ ] _HelloID_ environment.
- [ ] Access to the _HelloID_ API.
  - [ ] API Key
  - [ ] API Secret

### Remarks
> There is no functionality to "unrequest" a product, therefore this is just an empty script.

## Setup the connector

> _How to setup the connector in HelloID._ Are special settings required. Like the _primary manager_ settings for a source connector.

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/

