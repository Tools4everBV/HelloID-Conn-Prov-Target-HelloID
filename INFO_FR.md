HelloID est le nom de notre solution de Gestion des Identités et Accès (GIA). En plus de cela, il existe également un connecteur cible HelloID. Cet article explore en détail le connecteur cible HelloID. Grâce au connecteur cible HelloID, vous pouvez relier HelloID Provisioning aux modules Access Management et Service Automation de la solution de GIA. Cette intégration offre aux utilisateurs des fonctionnalités telles que le Single Sign-On (SSO), les produits en libre-service et les formulaires délégués. Découvrez les possibilités et avantages de cette intégration.

## Qu’est-ce que HelloID

HelloID est une solution de GIA de Tools4ever qui aide les organisations à gérer et sécuriser les identités numériques et les droits d'accès. HelloID permet une gestion centralisée des authentifications, des autorisations et du provisioning des utilisateurs, simplifiant ainsi la gestion des comptes utilisateurs et des droits d'accès.

La solution IAM comprend plusieurs modules, chacun offrant des fonctionnalités spécifiques :

* **Provisioning :** Automatise le processus de création, modification, désactivation et suppression des comptes utilisateurs en se basant sur les informations provenant d'un système source (RH).
* **Service Automation :** Rationalise les demandes courantes au sein de l'organisation, comme les demandes d'accès. Il offre des capacités de libre-service et permet de déléguer des tâches.
* **Access Management :** Fournit aux utilisateurs un accès rapide, convivial et sécurisé à toutes les applications dont ils ont besoin.

Il est important de noter que le module HelloID Provisioning est complètement séparé, tant techniquement que financièrement, des modules Access Management et Service Automation. Pour utiliser les modules Access Management et Service Automation, un compte HelloID est requis. Avec ce compte, les utilisateurs peuvent se connecter à HelloID et accéder aux fonctionnalités de SSO, aux produits en libre-service et aux formulaires délégués.

Les droits d'accès dans HelloID sont gérés via des groupes. Ces groupes et comptes utilisateurs spécifiques à Access Management et Service Automation forment ensemble HelloID Directory. HelloID Directory est similaire à un système comme Active Directory et permet une gestion centralisée des utilisateurs et de leurs droits d'accès. 

## Pourquoi une intégration HelloID est-elle utile ?
L'utilisation des modules Access Management et Service Automation de HelloID nécessite un compte utilisateur HelloID. Cependant, tous les utilisateurs de l'organisation ne se voient pas attribuer automatiquement un compte HelloID. Le connecteur HelloID, utilisé exclusivement comme connecteur cible, permet de combler cette lacune.

Le connecteur HelloID permet l'intégration avec des systèmes courants tels que : 

*	ADP
*	EasyVista

Des détails supplémentaires sur l'intégration avec ces systèmes sources sont fournis plus loin dans cet article.

## Comment Hello ID peut vous aider ?
**Créer des comptes plus rapidement :** L'intégration automatise le provisioning des utilisateurs dans HelloID, assurant que les utilisateurs ont automatiquement accès aux modules Access Management et Service Automation au bon moment. Cela libère le centre support de cette tâche et garantit un accès rapide et approprié aux utilisateurs.

**Gestion des comptes sans erreur :** Le connecteur améliore la gestion des comptes dans HelloID et prévient les erreurs. Cela est crucial, car des comptes et autorisations manquants peuvent causer beaucoup de frustration et de perturbation. Vous vous assurez également que les comptes sont désactivés en temps voulu après le départ des employés, évitant ainsi tout accès non autorisé. Cette gestion précise des droits d'accès réduit les opportunités pour les attaquants et améliore la sécurité numérique de votre organisation.

**Amélioration des niveaux de service :** L'intégration des différents modules de HelloID aide à améliorer vos niveaux de service. Vous pouvez ainsi mieux soutenir les utilisateurs en leur fournissant toujours les outils nécessaires pour travailler efficacement, augmentant ainsi leur satisfaction. 

## Comment HelloID Provisioning s'intègre-t-il aux autres modules HelloID ?

HelloID échange des informations entre HelloID Provisioning et les modules Access Management et Service Automation via l'API REST de HelloID. Pour utiliser cette API, il est nécessaire de créer une clé API et un secret dans HelloID.

| Changement dans le système source	| Procédure dans HelloID |
| --------------------------------- | ---------------------- |
| **Nouvel employé**	| Lorsqu'un nouvel employé rejoint l'entreprise, HelloID crée automatiquement un compte HelloID pour l'utilisateur. Tous les attributs du compte sont configurables. Si souhaité, HelloID active le compte automatiquement à la date de début du contrat via des règles métiers. |
| **Modification des données de l'employé**	| Les données d'un employé peuvent changer au cours de son contrat, comme le nom affiché ou le nom de connexion. HelloID peut ajuster toutes les informations des comptes HelloID au niveau des attributs. |
| **Changement de poste**	| Un changement de poste peut entraîner des modifications d'autorisations. HelloID ajuste automatiquement les autorisations dans HelloID en fonction des changements dans votre système source. |
| **Départ de l'employé**	| Lorsqu'un employé quitte l'entreprise, HelloID désactive automatiquement le compte utilisateur HelloID et informe l'employé concerné. Si souhaité, HelloID supprime automatiquement le compte après un certain délai. |

HelloID prend également en charge les autorisations dynamiques, qui fonctionnent toujours dans HelloID sur la base des données sources. Les autorisations dynamiques permettent par exemple de configurer tous les groupes de département sur la base d'une règle métier. HelloID identifie les corrélations entre les données sources et les groupes concernés. Contrairement aux autorisations régulières, les autorisations dynamiques s'adaptent automatiquement à la structure changeante de l’organisation.

De plus, l'intégration permet de demander des produits en libre-service. HelloID peut automatiquement attribuer un produit en libre-service sur la base des informations du système source.

## Intégration d'HelloID avec d'autres systèmes

* **Intégration HelloID - ADP :** Si vous utilisez HelloID comme seule User Directory et ne faites pas appel à d'autres systèmes sources comme Active Directory, Entra ID ou Google Workspace, HelloID peut automatiser de nombreuses tâches manuelles. Par exemple, après la création d'un compte HelloID, HelloID relie automatiquement le nom d'utilisateur utilisé au champ UPN dans ADP pour le Single Sign-On (SSO). Cela rationalise le processus, réduisant les manipulations manuelles et augmentant l'efficacité tout en diminuant les risques d'erreurs.

* **Intégration HelloID - EASYVISTA :** La connexion entre HelloID et EasyVista maintient les deux systèmes synchronisés, ce qui est crucial pour le SSO. Cela améliore la productivité des employés et renforce la sécurité. En même temps, vous simplifiez la gestion des comptes utilisateurs et des autorisations.

HelloID propose plus de 200 connecteurs, offrant une large gamme d'intégrations possibles entre HelloID et d'autres systèmes sources et cibles. Nous continuons d'étendre notre offre de connecteurs et d'intégrations, vous permettant ainsi d'intégrer HelloID avec tous les systèmes populaires. Vous trouverez un aperçu de tous les connecteurs disponibles ici.
