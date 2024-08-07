HelloID is the name of our Identity and Access Management (IAM) product. Additionally, there is also a HelloID target connector. This article delves deeper into the HelloID target connector. The HelloID Target Connector allows you to link HelloID Provisioning to the Access Management and Service Automation modules of the Identity & Access Management (IAM) solution. This connection provides users with access to Single Sign-On (SSO), Self-Service products, and delegated forms. This article discusses this integration, its capabilities, and benefits.

## What is HelloID?

HelloID is an IAM solution from Tools4ever that supports organisations in managing and securing both digital identities and access rights. HelloID enables the central management of user authentications, authorisations, and provisioning, thereby streamlining the management of user accounts and access permissions.

The IAM solution consists of several modules, each offering its own functionalities:

*	**Provisioning:** Automates the process of creating, modifying, and deleting user accounts based on information from a source system.
*	**Service Automation:** Streamlines common requests within the organisation, such as access requests. It offers capabilities in Self-Service and also enables the delegation of tasks.
*	**Access Management:** Provides users with quick and user-friendly access to all the applications they rely on.

It's important to note that the HelloID Provisioning module is completely separate—both technically and financially—from the Access Management and Service Automation modules. Therefore, an account in HelloID is required to use the Access Management and Service Automation modules. With this account, users can log in to HelloID and gain access to features including SSO integrations, Self-Service products, and delegated forms.

Access rights within HelloID are organised based on groups. These specific groups and user accounts for Access Management and Service Automation together form what is known as the HelloID Directory. The HelloID Directory is comparable to a system like Active Directory and enables central management of users and their access rights.

## Why is the HelloID connector useful?
Using HelloID's Access Management and Service Automation requires a user account in HelloID. However, not all users within an organisation are automatically assigned a HelloID account. The HelloID connector provides a solution and facilitates bridging this divide.

The HelloID connector — used as a target connector — enables integration with commonly used systems such as:

*	AFAS
*	TOPdesk

More details about these integrations are provided later in this article.

## HelloID assists you with:

**Quicker account creation:** The integration automates user provisioning within HelloID, ensuring users automatically gain access to the Access Management and Service Automation modules at the right time. This frees you from manual oversight and allows users quicker access to the correct permissions.

**Error-free account management:** The connection improves account management within HelloID and prevents errors. This is crucial because missing user accounts and permissions can cause significant frustration and disruption. It also ensures accounts are deactivated in a timely manner when employees leave, preventing unauthorised access. The connection ensures that users have only the necessary rights, reducing opportunities for attackers and enhancing your organisation’s digital security.

**Improved service levels:** Integrating the various modules of HelloID helps enhance your service levels. This allows you to support users more efficiently, ensuring they always have the right tools to perform their jobs optimally. This also boosts user satisfaction.

## How HelloID Provisioning integrates with other HelloID modules

HelloID exchanges information between HelloID Provisioning and the Access Management and Service Automation modules using the HelloID REST API. Utilising this requires the creation of an API key and secret within HelloID.

| Changes to source system | Procedure in HelloID |
| ------------------------ | -------------------- |
| **New employee** | 	When a new employee joins, HelloID automatically creates a HelloID account for the user. All attributes of the account are configurable. If desired, HelloID can automatically activate the account at the start of the employment, which you can configure in HelloID using business rules. |
| **Employee data changes** | 	During their tenure, employees may need updates to certain details, such as display or login names. HelloID can modify any aspect of an account's information, at the attribute level. |
| **Job role change** | 	Should an employee’s role change, which may involve different authorisations, HelloID automatically updates permissions based on the job changes recorded in your source system. |
| **Employee departure** | 	When an employee leaves, HelloID automatically deactivates the HelloID user account and informs the relevant employee. If desired, HelloID automatically deletes the HelloID account of the former employee after some time. |

HelloID also supports dynamic permissions, which in HelloID always operate based on source data. Dynamic permissions, for example, enable the configuration of all department groups based on a single business rule. HelloID identifies correlations between source data and the respective groups. Unlike regular, non-dynamic permissions, dynamic permissions automatically adjust to the changing structure of your organisation.

Additionally, the integration enables the request of Self-Service products. HelloID can automatically assign a Self-Service product based on your information from your source system. Note: withdrawing these products is not possible.

## Integrating HelloID with other systems via HelloID
You can integrate HelloID with various other systems. This allows you to link various source systems to HelloID, elevating the management of users and authorisations to a higher level. Some common integrations include:

**HelloID - AFAS connector:** If you use HelloID as the sole User Directory and do not use other source systems like Active Directory, Entra ID, or Google Workspace, HelloID can automate many manual tasks for you. For example, after creating a HelloID account, HelloID automatically syncs the username back to the UPN field in AFAS for Single Sign-On (SSO). This streamlines the process, reduces the number of manual tasks, increases efficiency, and reduces the likelihood of errors.

**HelloID - TOPdesk connector:** Linking HelloID with TOPdesk ensures both systems are fully synchronised, which is crucial for functionalities such as SSO. This enhances staff productivity and security while simplifying the management of user accounts and authorisations.

HelloID supports over 200 connectors, offering a broad spectrum of integration options between Ultimo and other source and target systems. We continually expand our range of connectors and integrations, allowing for comprehensive integration with all popular systems. A full list of available connectors can be found here.
