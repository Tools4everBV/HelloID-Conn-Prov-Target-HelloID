
# HelloID-Conn-Prov-Target-HelloID

> [!NOTE]  
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="https://github.com/Tools4everBV/HelloID-Conn-Prov-Target-HelloID/blob/master/Logo.png?raw=true">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-HelloID](#helloid-conn-prov-target-helloid)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Getting started](#getting-started)
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

| Endpoint               | Description                                                 |
| ---------------------- | ----------------------------------------------------------- |
| /api/v1/users/{UserId} | Get, update and delete user accounts (GET), (PUT), (DELETE) |
| /api/v1/users          | Create user accounts (POST)                                 |

The following lifecycle actions are available:

| Action               | Description                               |
| -------------------- | ----------------------------------------- |
| create.ps1           | Create or correlate to an account         |
| delete.ps1           | Delete an account                         |
| disable.ps1          | Disable an account                        |
| enable.ps1           | Enable an account                         |
| update.ps1           | Update an account                         |
| grantPermission.ps1  | PowerShell _grant_ lifecycle action       |
| revokePermission.ps1 | PowerShell _revoke_ lifecycle action      |
| permissions.ps1      | PowerShell _permissions_ lifecycle action |
| resources.ps1        | PowerShell _resources_ lifecycle action   |
| configuration.json   | Default _configuration.json_              |
| fieldMapping.json    | Default _fieldMapping.json_               |

## Getting started

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

| Setting   | Description                      | Mandatory |
| --------- | -------------------------------- | --------- |
| BaseUrl   | The URL to the API               | Yes       |
| ApiKey    | The Key to connect to the API    | Yes       |
| ApiSecret | The Secret to connect to the API | Yes       |

### Prerequisites

### Remarks

## Setup the connector

> _How to setup the connector in HelloID._ Are special settings required. Like the _primary manager_ settings for a source connector.

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/

