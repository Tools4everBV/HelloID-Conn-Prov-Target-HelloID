Mit der HelloID Target Connector können Sie HelloID Provisioning mit den Modulen Access Management und Service Automation von HelloID verbinden. Diese Verbindung gewährt Benutzern Zugriff auf Single Sign-On (SSO), Self-Service-Produkte und delegierte Formulare. In diesem Artikel erfahren Sie mehr über die HelloID Target Connector, ihre Möglichkeiten und Vorteile.

## Was ist HelloID?

HelloID ist eine IAM-Lösung von Tools4ever, die Organisationen bei der Verwaltung und Sicherung sowohl digitaler Identitäten als auch von Zugriffsrechten unterstützt. Sie ermöglicht die zentrale Verwaltung von Benutzer-Authentifizierungen, Autorisierungen und Provisioning, wodurch Benutzerkonten und Zugriffsrechte effizient verwaltet werden können.

Die IAM-Lösung besteht aus mehreren Modulen, die jeweils eigene Funktionen bieten:

* **Provisioning:** Automatisiert das Erstellen, Ändern und Löschen von Benutzerkonten basierend auf Informationen aus einem Quellsystem.
* **Service Automation:** Rationalisiert häufige Anfragen in der Organisation, wie Zugriffsanfragen, und bietet unter anderem Self-Service-Möglichkeiten sowie die Delegation von Aufgaben.
* **Access Management:** Bietet Benutzern schnellen und benutzerfreundlichen Zugriff auf alle vertrauenswürdigen Anwendungen.

Wichtig zu beachten ist, dass das HelloID Provisioning-Modul vollständig von den Modulen Access Management und Service Automation getrennt ist - sowohl technisch als auch finanziell. Für die Nutzung der Module Access Management und Service Automation ist ein Konto in HelloID erforderlich. Mit diesem Konto können Benutzer sich bei HelloID anmelden und auf SSO-Verbindungen, Self-Service-Produkte und delegierte Formulare zugreifen.

Zugriffsrechte in HelloID werden gruppenbasiert geregelt. Diese Gruppen und Benutzerkonten für spezifisches Access Management und Service Automation bilden das sogenannte HelloID Directory, vergleichbar mit einem System wie Active Directory und ermöglichen die zentrale Verwaltung von Benutzern und ihren Zugriffsrechten.

## Warum ist die Verbindung mit HelloID nützlich?

Die Nutzung von HelloID Access Management und Service Automation erfordert ein Benutzerkonto in HelloID. Nicht alle Benutzer in der Organisation erhalten jedoch standardmäßig ein HelloID-Konto. Der HelloID Connector bietet eine Lösung und ermöglicht die Überbrückung dieser Trennung.

Der HelloID Connector - ausschließlich als Ziel-Connector eingesetzt - ermöglicht Verbindungen mit weit verbreiteten Systemen wie:

* AFAS
* TOPdesk

Weitere Details zur Verbindung mit diesen Quellsystemen finden Sie weiter unten im Artikel.

## HelloID unterstützt Sie bei:

**Schnelleres Erstellen von Accounts:** Die Integration automatisiert das User-Provisioning in HelloID, sodass Benutzer automatisch zum richtigen Zeitpunkt Zugang zu den Modulen Access Management und Service Automation innerhalb von HelloID haben. So müssen Sie sich darum nicht kümmern und Benutzer erhalten schneller den richtigen Zugang.

**Fehlerfreies Account-Management:** Die Verbindung hebt das Management von Konten in HelloID auf ein höheres Niveau und verhindert dabei Fehler. Fehlen Benutzerkonten und Berechtigungen, kann das viel Ärger und Unannehmlichkeiten verursachen. Auch stellt die Verbindung sicher, dass Konten nach dem Austritt von Mitarbeitern rechtzeitig deaktiviert werden und unautorisierter Zugang verhindert wird. Die Verbindung sorgt dafür, dass Benutzer nie mehr Rechte haben, als notwendig, was Angreifern unnötige Chancen bietet und erhöht somit die digitale Sicherheit Ihrer Organisation.

**Verbesserte Servicelevel:** Die Integration der verschiedenen HelloID-Module hilft dabei, Ihr Servicelevel zu verbessern. So können Sie Benutzer schneller unterstützen, sodass sie immer über die richtigen Mittel verfügen, um ihre Arbeit optimal zu erledigen. Dies verstärkt die Zufriedenheit der Benutzer.

## Wie HelloID Provisioning mit anderen HelloID-Modulen integriert

HelloID tauscht Informationen zwischen HelloID Provisioning und den Modulen Access Management und Service Automation mittels der HelloID REST API aus. Diese Nutzung erfordert die Erstellung eines API-Keys und eines Geheimnisses innerhalb von HelloID.

| Änderung im Quellsystem | Verfahren in HelloID |
| --------------------------- | ----------------- |
| **Neue/r Mitarbeiter/in** | Wenn ein/e neue/r Mitarbeiter/in eingestellt wird, erstellt HelloID automatisch ein HelloID-Konto für die/den Benutzer/in. Alle Attribute des Kontos sind dabei konfigurierbar. Auf Wunsch aktiviert HelloID das Konto automatisch zum Start des Arbeitsverhältnisses, was Sie in HelloID mithilfe von Business Rules konfigurieren. |
| **Änderung von Mitarbeiterdaten** | Verschiedene Daten eines Mitarbeiters können während des Arbeitsverhältnisses geändert werden, wie z.B. Anzeigename oder Login-Name. HelloID kann alle Informationen von HelloID-Konten auf Attribut-Ebene anpassen. |
| **Funktionsänderung** | Wenn sich die Funktion eines Mitarbeiters ändert, kann das andere Autorisierungen erfordern. HelloID passt die Berechtigungen in HelloID automatisch entsprechend den Funktionsänderungen an, die im Quellsystem vorgenommen wurden. |
| **Austritt eines Mitarbeiters** | HelloID deaktiviert bei Austritt automatisch das HelloID-Benutzerkonto und informiert die/den betroffene/n Mitarbeiter/in darüber. Auf Wunsch löscht HelloID das HelloID-Konto der/des ehemaligen Mitarbeiters/in nach einer bestimmten Zeitspanne automatisch. |

HelloID unterstützt auch dynamische Berechtigungen, die in HelloID immer auf der Grundlage von Quelldaten funktionieren. Dynamische Berechtigungen ermöglichen beispielsweise die Einrichtung aller Abteilungsgruppen basierend auf einer Business Rule. HelloID identifiziert dabei Korrelationen zwischen Quelldaten und den betreffenden Gruppen. Im Gegensatz zu regulären, nicht-dynamischen Berechtigungen passen sich dynamische Berechtigungen automatisch der sich ändernden Organisationsstruktur an.

Darüber hinaus ermöglicht die Integration das Anfordern von Self-Service-Produkten. HelloID kann dabei auf der Grundlage Ihrer Informationen aus Ihrem Quellsystem ein Self-Service-Produkt automatisch zuweisen. Hinweis: Der automatische Entzug dieser Produkte über HelloID ist nicht möglich, kann jedoch manuell oder automatisiert über das Self-Service-Produkt eingerichtet werden.

## HelloID mit Systemen verbinden

HelloID lässt sich mit verschiedenen anderen Systemen integrieren. Sie können unter anderem verschiedene Quellsysteme mit HelloID verbinden und so das Management von Benutzern und Autorisierungen auf ein höheres Niveau heben. Zu den häufigsten Integrationen gehören:

* **HelloID - AFAS-Verbindung:** Wenn das HelloID-Verzeichnis Ihr primäres Benutzerverzeichnis ist und SSO bereitstellt, muss das UPN-Feld in AFAS mit dem Wert aus dem HelloID-Verzeichnis gefüllt werden. Die Provisioning-Verbindung mit HelloID kann diesen Prozess automatisieren. Dies vereinfacht den Prozess und reduziert die Anzahl manueller Eingriffe, was die Effizienz erhöht und die Fehleranfälligkeit verringert.

* **HelloID - TOPdesk-Verbindung:** Die Verbindung zwischen HelloID und TOPdesk hält die beiden Systeme vollständig synchron, was insbesondere für SSO wichtig ist. Dies erhöht die Produktivität der Mitarbeiter und verbessert die Sicherheit. Gleichzeitig wird das Management sowohl von Benutzerkonten als auch von Autorisierungen vereinfacht.

HelloID unterstützt über 200 Konnektoren. Wir bieten daher eine breite Palette an Integrationsmöglichkeiten zwischen HelloID und anderen Quell- und Zielsystemen. Unser Angebot an Konnektoren und Integrationen wird kontinuierlich erweitert, sodass Sie sich mit allen gängigen Systemen integrieren können.