HelloID is de Identity & Access Management (IAM)-oplossing van Tools4ever. Met behulp van de HelloID Target Connector koppel je HelloID Provisioning aan de modules Access Management en Service Automation van HelloID. De koppeling geeft gebruikers onder meer toegang tot Single Sign-On (SSO), Self-Service producten en gedelegeerde formulieren. In dit artikel lees je meer over de HelloID Target Connector, de mogelijkheden en voordelen.

## Wat is HelloID? 

HelloID is een IAM-oplossing van Tools4ever die organisaties ondersteunt bij het beheren en beveiligen van zowel digitale identiteiten als toegangsrechten. HelloID maakt het centraal beheren van gebruikersauthenticaties, autorisaties en provisioning mogelijk. Het stroomlijnt zo het beheer van gebruikersaccounts en toegangsrechten. 

De IAM-oplossing bestaat uit meerdere modules, die ieder eigen functionaliteiten bieden:

*	**Provisioning:** automatiseert het proces van het aanmaken, wijzigen en verwijderen van gebruikersaccounts op basis van informatie uit een bronsysteem. 
*	**Service Automation:** stroomlijnt veelvoorkomende verzoeken binnen de organisatie, zoals toegangsverzoeken. Het biedt onder meer mogelijkheden op het gebied van Self-Service. Ook maakt de module het delegeren van taken mogelijk.
*	**Access Management:** biedt gebruikers snelle en gebruiksvriendelijke toegang tot alle applicaties waarop zij vertrouwen.

Belangrijk om op te merken is dat de HelloID Provisioning-module volledig is gescheiden - zowel technisch als financieel - van de modules Access Management en Service Automation. Voor het gebruik van de modules Access Management en Service Automation is daardoor een account in HelloID vereist. Met behulp van dit account kunnen gebruikers inloggen op HelloID en krijgen zij toegang tot onder meer SSO-koppelingen, Self-Service producten en gedelegeerde formulieren. 

Toegangsrechten binnen HelloID zijn geregeld op basis van groepen. Deze groepen en gebruikersaccounts voor specifiek Access Management en Service Automation vormen samen de zogeheten HelloID Directory. De HelloID Directory is vergelijkbaar met een systeem als Active Directory en maakt het centraal beheren van gebruikers en hun toegangsrechten mogelijk. 

## Waarom is HelloID koppeling handig?
Het gebruik van HelloID Access Management en Service Automation vereist een gebruikersaccount in HelloID. Niet alle gebruikers binnen de organisatie krijgen echter standaard een HelloID-account toegewezen. De HelloID connector biedt uitkomst en maakt het overbruggen van deze scheiding mogelijk.

De HelloID connector - die uitsluitend wordt ingezet als doelconnector - maakt een koppeling met veelvoorkomende systemen mogelijk, zoals: 

*	AFAS
*	TOPdesk

Verdere details over de koppeling met deze bronsystemen zijn te vinden verderop in het artikel.

## HelloID helpt je met

**Sneller accounts aanmaken:** De integratie automatiseert user provisioning binnen HelloID en zorgt dat gebruikers automatisch op het juiste moment toegang hebben tot de modules Access Management en Service Automation binnen HelloID. Zo heb jij hiernaar geen omkijken en beschikken gebruikers sneller over de juiste toegang.

**Foutloos accountbeheer:** De koppeling tilt het beheer van accounts binnen HelloID naar een hoger niveau en voorkomt daarbij fouten. Prettig, want ontbrekende gebruikersaccounts en permissies kunnen veel ergernis en overlast veroorzaken. Ook zorg je dat je accounts na vertrek van werknemers tijdig deactiveert en je ongeautoriseerde toegang voorkomt. De koppeling stelt zeker dat gebruikers nooit over meer rechten beschikken dan noodzakelijk, iets wat aanvallers onnodige kansen kan bieden. Je tilt zo de digitale veiligheid van je organisatie naar een hoger niveau. 

**Verbeterde serviceniveaus:** De integratie van de verschillende modules van HelloID helpt met het verbeteren van je serviceniveau. Zo kan je gebruikers sneller ondersteunen, zodat zij altijd over de juiste middelen beschikken voor het optimaal uitvoeren van hun werk. Je versterkt hiermee de gebruikerstevredenheid. 

## Hoe HelloID Provisioning integreert met andere HelloID modules

HelloID wisselt informatie uit tussen HelloID Provisioning en de modules Access Management en Service Automation met behulp van de HelloID REST API. Het gebruik hiervan vraagt om het aanmaken van een API-key en secret binnen HelloID.

| Wijziging in bronsysteem| 	Procedure in HelloID | 
| ----------------------------------------- | --------------------------|
|**Nieuwe medewerker**|	Indien een nieuwe medewerker in dienst treedt, maakt HelloID automatisch een HelloID-account aan voor de gebruiker. Alle attributen van het account zijn daarbij configureerbaar. Indien gewenst activeert HelloID het account automatisch bij de start van het dienstverband, wat je vanuit HelloID configureert met behulp van business rules.|
| **Gegevens van medewerker wijzigen** |	Allerlei gegevens van een medewerker kunnen gedurende diens dienstverband wijzigen. Denk hierbij aan de weergave- of inlognaam. HelloID kan alle informatie van HelloID-accounts op attribuutniveau aanpassen.|
| **Functiewijziging** |	Indien een functie van een medewerker verandert, kan dit ook andere autorisaties met zich meebrengen. HelloID past de permissies in HelloID automatisch aan op functiewijzigingen die in je bronsysteem zijn doorgevoerd.|
| **Medewerker treedt uit dienst** | HelloID deactiveert bij uitdiensttreding automatisch het HelloID-gebruikersaccount en informeert betrokken medewerker hierover. Indien gewenst verwijdert HelloID na verloop van tijd automatisch het HelloID-account van de oud-medewerker.|

HelloID biedt ook ondersteuning voor dynamische permissies, die in HelloID altijd werken op basis van brondata. Dynamische permissies maken bijvoorbeeld het inregelen alle afdelingsgroepen op basis van één business rule mogelijk. HelloID identificeert daarbij correlaties tussen brongegevens en de desbetreffende groepen. In tegenstelling tot reguliere, niet-dynamische permissies bewegen dynamische permissies automatisch mee met de veranderende structuur van jouw organisatie. 

Daarnaast maakt de integratie het aanvragen van Self-Service producten mogelijk. HelloID kan daarbij op basis van je informatie uit je bronsysteem een Self-Service product automatisch toekennen. Let op: het automatisch intrekken van deze producten via HelloID is niet mogelijk, maar kan wel handmatig of geautomatiseerd via het Self-Service product ingesteld worden. 

## HelloID koppelen met HelloID systemen

Je kunt HelloID integreren met diverse andere systemen. Zo kan je onder meer diverse bronsystemen aan HelloID koppelen, en zo het beheer van gebruikers en autorisaties naar een hoger niveau tillen. Enkele veelvoorkomende integraties zijn:

* **HelloID - AFAS koppeling:** Indien de HelloID-directory je primaire gebruikersdirectory is en SSO verzorgt, moet het UPN-veld in AFAS gevuld worden met de waarde uit de HelloID-directory. De provisioning-koppeling met HelloID kan dit proces automatiseren. Dit stroomlijnt het proces en vermindert het aantal handmatige handelingen, wat de efficiëntie vergroot en foutgevoeligheid verkleint. 

* **HelloID - TOPdesk koppeling:** De koppeling tussen HelloID en TOPdesk houdt de twee systemen volledig in-sync, wat van belang is met het oog op onder meer SSO. Je verhoogt zo de productiviteit van medewerkers en verbetert de beveiliging. Tegelijkertijd vereenvoudig je het beheer van zowel gebruikersaccounts als autorisaties. 

HelloID ondersteunt ruim 200 connectoren. We bieden dan ook een breed scala aan integratiemogelijkheden tussen HelloID en andere bron- en doelsystemen. We breiden ons aanbod aan connectoren en integraties continu uit, waardoor je met alle populaire systemen kunt integreren.
