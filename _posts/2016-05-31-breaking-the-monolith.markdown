---
layout: post
title:  "Breaking the Monolith"
date:   2016-05-31 08:05:00 +0100
categories: microservice architecture soa
image: /assets/images/monolith.jpg
---


## Migrating to Micro-Services at Jumo

In this article, I’ll discuss some of the approaches and technologies we used at [Jumo](https://jumo.world) to turn our legacy, monolithic mobile money loan system into an ecosystem of micro-services.

<!--more-->

*Developers cautiously approach a monolithic application (2001: A Space Odyssey)*

## What makes a micro-service?
Micro-services is an approach to system architecture arising from the convergence of several technologies:

- **[Service-orientated architecture](https://gist.github.com/chitchcock/1281611)** teaches us to construct ecosystems of separate, collaborating components.
- **[Cloud computing](https://en.wikipedia.org/wiki/AWS_Elastic_Beanstalk)**, especially platform-as-a-service, makes server provisioning trivial.
- **Modern web technologies** such as [REST](https://en.wikipedia.org/wiki/Representational_state_transfer), [HTTP](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes) and [JSON](http://www.json.org/) guide us toward creating sane service APIs.
- **Modern programming languages** have excellent support for creating web [servers](https://wyeworks.com/blog/2015/4/20/rails-api-is-going-to-be-included-in-rails-5/) and [clients](https://github.com/jnunemaker/httparty).
- Distributed systems theory teaches us core design principles including [idempotency](https://en.wikipedia.org/wiki/Idempotence), [message-delivery semantics](http://bravenewgeek.com/you-cannot-have-exactly-once-delivery/) and [CAP theorem](https://en.wikipedia.org/wiki/CAP_theorem).
- **[Systems thinking](https://en.wikipedia.org/wiki/Systems_thinking)** teaches us to design holistically, considering the system as a whole.

This combination of technologies enables the creation of granular micro-services that can be said to be responsible for a single domain of the business. They aim to solve that area of business, serving as a *one-stop shop* for features and enhancements related to that domain. Business staff imagine it as a *black box* that runs autonomously, performing their whims and *taking care of* that part of the business.

## What are some advantages of micro-services?
- **System design is simplified** because it’s easier to discuss and reason about a service responsible for a single business domain.
- **Implementing changes is easier** because the scope of each service is limited.
- **Blast radius is limited** in the event of an infrastructure outage because each micro-service is hosted on separate hardware and each client can define explicit fail-open or -closed semantics.
- Services can be **administered and scaled independently**, in response to customer, business or engineering needs.

![Migrating to Micro-services](/assets/images/migrating_to_microservices.png)
*Developers migrating to micro-services - (classicprogrammerpaintings.com)*

## How we positioned ourselves for micro-services migration
We identified a **critical path** in the system that brings in money for the business, undergoes frequent changes, is a source of bugs, causes confusion and incurs operational overhead. The case at hand: *We need to improve and streamline the subsystems that control how much money we can offer to loan to a given customer*.

We developed a **common vision** in collaboration with business as to how that critical path would look in the context of micro-services. A series of brain-storming sessions were held with stakeholders across departments with the purpose being to draw a 50-kilometre-view architecture diagram.

Various collaborating services were identified, along with their inputs and outputs. It was agreed which departments would *own* which components. An *Offer service* was identified, that can be administered by the Credit Risk department, and a *Fraud service* was identified, that can be administered by the Fraud Department.

These sessions included the adoption and definition of a glossary or **ubiquitous language** and help ensure that there is not a critical business stakeholder, process or requirement omitted now that would become a project-killer later on.

One tip for these sessions is to consider all customer data as amorphous **consumable data** that can be passed around or retrieved at will. Don’t worry too much about the specific structure of the data, as long as you know it will be available. In practice, this is usually a routine engineering problem and need not derail big vision talks. *The Offer service is going to need all of a customer’s data in order to assign them a credit risk score. Let’s make the simplifying assumption that all that data is vended by some service.*

Now that the scaffolding of a common vision had been established, we **looked for opportunities arising from business** to create the envisioned services. This involves scrutinising all incoming work requirements for design overlap with the stated vision. *The Credit Risk team wants to make frequent changes to the business rules for assigning credit risk scores. We could make a decision engine in the Offer service with a centralised UI so they can administrate these rules in self-service fashion.*

**We created the envisioned services as soon as there was a business need that could be fulfilled by doing so.** It’s important that new services are spun up quickly so business is not delayed. Initially, these services were largely skeletons, comprising just one or two API calls or a background job. They tend to grow quickly as functionality is migrated from the legacy system and new features are added. *Let’s set up a skeleton Fraud service for this API call. I’m sure more functionality will move there shortly.*

**A common technology stack** were employed across the micro-services and the legacy application, making code-sharing trivial. Best practices and styles are enforced identically across all projects. We found that it was better initially to simply share (i.e. copy-pasta) common code across services than to attempt to package common code into separate libraries or repositories at this early stage.

## Hollow monolith (hollow-lith)
The monolithic legacy application increasingly took on — or was relegated to — the following roles, as more and more functionality was peeled off to the new micro-services:

- User permission and group management
- Centralised user interface
- Global search
- Database administration

While each micro-service has direct access only to its own database, the legacy application has access to all databases. This was useful for various reasons:

- It preserved the centralised UI and global search functionality of the monolithic legacy application
- It eased data migration, enabling the use of techniques such as double-reads and -writes to move large live tables off the main production database and legacy system into a micro-service.

## Enabling tech we found essential

- **Decision management systems** (developed in-house) allow business to administrate directly the business rules that govern their area of the business. *Credit risk can update their scoring rules any time — they don’t need Engineering to do this.*

- **Self-service user interfaces** (developed in-house) allow business to administrate themselves without engineering needing to be the loop. *The Fraud department can load new blacklists whenever they like — they don’t need Engineering to do this.*

- An **event-based notification system** (Amazon SNS) is a useful way for events to be syndicated across the system to subscribers that have registered their interest. *Scoring occurs whenever we get new customer data. We’ll also send out messaging to that customer with their latest offer.*

- A **fully-fledged RDBMS database system** (MySQL) provides powerful functionality that assists with partitioning data from the legacy production database and migrating it safely to micro-services. An effective technique is hosting multiple databases on the same physical host, because queries may then refer to all databases.

- **API specification and mocking** (Apiary) allows APIs to be agreed upon before development starts. It enables rapid development because it automatically generates and hosts live mocks for both the client and server.

- **Unified logging, metrics and dashboarding** (Sumo Logic): It’s easier to identify issues and validate behaviour when all logs are in one place. Unified logging, metrics, dashboards and alerts are essential to ensure that deployments are rolled out correctly and for demonstrating to the customer that the feature or fix is working.

## What went wrong and what we learned

We did **too much upfront design and implementation** on the first service we broke out, deviating from business requirements in order to try make the ultimate system in the first iteration. Over-engineering a service too early is an enormous mistake. This backfired badly and resulted in a lot of wasted effort. **How we recovered**: We built-in a bypass for the over-engineered system while we worked to address the underlying issues. **What we learned**: Design for the business problem at hand. Work simply, don’t preclude future design flexibility and empower business to actually request the functionality they need before preemptively implementing it based on imagined use cases.

We initially attempted to use a **completely different technology stack** from the legacy monolithic application. Despite being a working implementation, this service never gained traction or mind-share , purely because of the technological learning curve. **How we recovered**: The service was re-implemented using the same technology as the monolithic application. **What we learned**: Employ a homogeneous stack as far as is possible .

We performed some migrations by replacing method calls with HTTP requests to micro-services. This introduced significant performance overhead and resulted in a background batch job being unable to scale. **How we recovered**: We converted the offline batch job into an online per-request job. **What we learned**: Be conscious of the trade-offs between per-request or batch interfaces. Especially, avoid creating processes that rapidly issue similar HTTP requests for each of many records.

## Conclusion
Micro-service architecture is a powerful design philosophy when approached correctly. However, getting it wrong can be painful indeed. In particular, the same team who created the monolithic system is unlikely to be in a position to migrate it to micro-services successfully. To paraphrase an old saying: *A monolithic application makes it easy to shoot yourself in the foot. Using micro-services makes it harder; but if you do, you blow off your whole leg.*

_Jumo offers loans to more than 5 million customers in Africa based on their mobile phone usage.
The money is paid and re-paid into their mobile money wallets, which are associated with their SIM cards.
At the stage this article was written, turnover was more than 10 million USD per month.
The area of the business being discussed here (core) is primarily Ruby on Rails on Heroku and AWS.
The engineering team (core) at the time comprised 5 - 10 engineers._
