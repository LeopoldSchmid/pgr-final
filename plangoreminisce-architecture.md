# PlanGoReminisce - Architecture Documentation

**About arc42**

arc42, the template for documentation of software and system architecture.

Template Version 8.2 EN. (based upon AsciiDoc version), January 2023

Created, maintained and © by Dr. Peter Hruschka, Dr. Gernot Starke and contributors. See <https://arc42.org>.

::: note
This architecture documentation follows the arc42 template and serves as the comprehensive technical guide for the PlanGoReminisce collaborative trip planning application.
:::

# Introduction and Goals {#section-introduction-and-goals}

## Project Overview

**PlanGoReminisce** is a collaborative trip planning web application designed to transform the typically solo effort of trip planning into a shared, enjoyable experience among friends. The application supports users throughout the entire trip lifecycle: planning (before), companion (during), and reminiscing (after).

## Requirements Overview {#_requirements_overview}

### Functional Requirements

**Core Planning Features:**
- **User Management**: Secure user accounts with role-based permissions (Owner, Co-Owner, Member, Guest)
- **Trip Creation & Invitation**: Create trips and invite participants via email with automatic account creation flow
- **Date Coordination**: Collaborative date finding with availability calendars and proposal systems
- **Location Planning**: Destination discussion and decision support
- **Expense Management**: Comprehensive expense tracking, splitting, and settlement with multiple algorithms
- **Meal Planning**: Recipe management, meal scheduling, and shopping list generation
- **Shopping Lists**: Aggregated ingredient lists with store-optimized views and purchase tracking
- **Item Management**: Shared item lists for trip essentials with assignment capabilities
- **Communication**: Discussion forums for trip-related topics

**Lifecycle Support:**
- **Planning Phase**: All collaborative planning tools active
- **Go Phase**: Mobile-optimized expense tracking and shopping list management
- **Reminisce Phase**: Trip summaries, photo sharing, and data for future trip reuse

**Technical Requirements:**
- **Progressive Web App**: Works seamlessly on desktop and mobile
- **Offline Capability**: Basic functionality available without internet
- **Real-time Collaboration**: Live updates for shared activities
- **Data Export/Import**: Reuse recipes and learnings across trips

### Quality Goals {#_quality_goals}

| Priority | Quality Goal | Scenario | Motivation |
|----------|-------------|----------|-------------|
| 1 | **Simplicity** | A 60+ year old user can create a trip and invite friends within 5 minutes | Reduce barriers to adoption and usage |
| 2 | **Collaboration** | Multiple users can simultaneously plan meal schedules without conflicts | Core value proposition of shared planning |
| 3 | **Mobile-First** | All core functions work seamlessly on smartphones | Essential for usage during trips |
| 4 | **Performance** | Page loads complete within 2 seconds on 3G connections | Ensures usability in various network conditions |
| 5 | **Reliability** | 99.5% uptime during peak planning seasons | Users depend on the app for trip coordination |

### Stakeholders {#_stakeholders}

| Role/Name | Contact | Expectations |
|-----------|---------|--------------|
| **Primary Users** | Trip planners and participants | Intuitive collaboration tools, mobile accessibility, reliable data sync |
| **Developer/Owner** | Leo | Maintainable architecture, simple deployment, cost-effective hosting |
| **System Administrator** | Leo | Minimal maintenance overhead, clear monitoring, automated deployments |

# Architecture Constraints {#section-architecture-constraints}

## Technical Constraints

| Constraint | Description | Rationale |
|------------|-------------|-----------|
| **Rails 8.0+** | Must use Ruby on Rails 8.0 or later | Access to Solid adapters, built-in auth, modern features |
| **Single Server** | Deploy to single Hetzner server initially | Cost optimization and simplicity |
| **SQLite/PostgreSQL** | Database choice limited to these options | Rails 8 Solid adapters compatibility |
| **No External Services** | Minimize dependencies on Redis, Sidekiq, etc. | Rails 8 "No PaaS Required" philosophy |

## Organizational Constraints

| Constraint | Description | Rationale |
|------------|-------------|-----------|
| **Solo Development** | Single developer (Leo) for initial version | Resource limitation |
| **Self-Hosted** | Must be deployable to personal Hetzner server | Independence from PaaS providers |
| **German/English** | Support both languages | User base requirements |

## Quality Constraints

| Constraint | Description | Rationale |
|------------|-------------|-----------|
| **Mobile-First** | All features must work on smartphones | Primary usage context during trips |
| **Progressive Enhancement** | Works without JavaScript for core features | Reliability and accessibility |
| **Offline-Friendly** | Basic read functionality when offline | Network unreliability during travel |

# Context and Scope {#section-context-and-scope}

## Business Context {#_business_context}

```
[Trip Participants] ←→ [PlanGoReminisce] ←→ [Email Service]
       ↑                        ↓
[Mobile Browsers]        [Payment Services]
       ↑                        ↓
[Desktop Browsers]      [File Storage]
```

**Communication Partners:**

| Partner | Input | Output |
|---------|-------|--------|
| **Trip Participants** | Trip data, availability, expenses, preferences | Trip information, notifications, summaries |
| **Email Service** | Delivery confirmations | Invitation emails, notifications |
| **Payment Services** | Payment confirmations | Payment requests, IBAN transfers |
| **File Storage** | Recipe images, trip photos | Stored media files |

## Technical Context {#_technical_context}

```
[Web Browsers] ←HTTP/HTTPS→ [Rails App] ←→ [SQLite/PostgreSQL]
       ↑                          ↓
[Hotwire Native] ←→ [Background Jobs] ←→ [File System]
       ↓                          ↓
[Mobile Apps]              [Email SMTP]
```

**Technical Interfaces:**

| Interface | Protocol | Usage |
|-----------|----------|-------|
| **Web Interface** | HTTPS | Primary user interaction |
| **Database** | Direct/Connection Pool | Data persistence |
| **Email SMTP** | SMTP/TLS | Invitation and notification emails |
| **File Storage** | File System/S3 | Recipe images and attachments |
| **Background Processing** | Solid Queue | Async tasks and jobs |

# Solution Strategy {#section-solution-strategy}

## Technology Decisions

**Web Framework: Ruby on Rails 8.0+**
- **Rationale**: Rails 8's "No PaaS Required" philosophy aligns with self-hosting goals
- **Benefits**: Built-in authentication, Solid adapters eliminate Redis dependency, Kamal 2 for deployment
- **Trade-offs**: Ruby ecosystem vs. other modern stacks

**Frontend Strategy: Hotwire + Progressive Enhancement**
- **Rationale**: Simplicity over complex SPA frameworks, mobile-first approach
- **Benefits**: Server-rendered HTML, real-time updates, native mobile app foundation
- **Trade-offs**: Less interactive UI vs. better performance and simplicity

**Database Strategy: SQLite → PostgreSQL Migration Path**
- **Rationale**: Start simple with SQLite, scale to PostgreSQL when needed
- **Benefits**: Rails 8 Solid adapters make SQLite production-viable
- **Trade-offs**: Eventual migration complexity vs. initial simplicity

**Deployment Strategy: Kamal 2 + Single Server**
- **Rationale**: Cost-effective, simple management, included in Rails 8
- **Benefits**: Single command deployment, Docker containerization
- **Trade-offs**: Single point of failure vs. operational simplicity

## Architectural Patterns

**Domain-Driven Design**
- Clear separation between Trip, User, Expense, Recipe, and Planning domains
- Rich domain models with business logic encapsulation

**Component-Based Frontend**
- ViewComponent for reusable UI elements
- Stimulus controllers for JavaScript behavior
- Modular CSS with Tailwind

**Event-Driven Background Processing**
- Solid Queue for expense calculations, email sending
- Async processing of heavy operations

## Quality Achievement Strategies

**Simplicity**: Rails conventions, minimal configuration, built-in solutions
**Collaboration**: Real-time updates via Turbo Streams, optimistic UI updates
**Mobile-First**: Responsive design, touch-optimized interfaces, offline caching
**Performance**: Database indexing, background processing, CDN for assets
**Reliability**: Comprehensive testing, monitoring, automated deployment

# Building Block View {#section-building-block-view}

## Whitebox Overall System {#_whitebox_overall_system}

```
┌─────────────────────────────────────────────────────────────┐
│                    PlanGoReminisce                          │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │    Web      │  │   Mobile    │  │   Background        │ │
│  │ Interface   │  │ Interface   │  │   Processing        │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              Business Logic Layer                       │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │ │
│  │  │   Trip   │ │  User    │ │ Expense  │ │  Recipe  │  │ │
│  │  │ Domain   │ │ Domain   │ │ Domain   │ │ Domain   │  │ │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                Data Layer                               │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │ │
│  │  │ Database │ │   File   │ │  Cache   │ │  Queue   │  │ │
│  │  │          │ │ Storage  │ │          │ │          │  │ │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Contained Building Blocks

| Component | Responsibility |
|-----------|----------------|
| **Web Interface** | HTTP request handling, HTML rendering, user session management |
| **Mobile Interface** | Hotwire Native wrapper, mobile-optimized views |
| **Background Processing** | Async job processing, email sending, calculations |
| **Business Logic Layer** | Domain models, business rules, validation |
| **Data Layer** | Data persistence, caching, file storage, job queue |

## Level 2 - Business Logic Decomposition

### Trip Domain

```
┌─────────────────────────────────────────────────────────────┐
│                    Trip Domain                              │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │    Trip     │  │   Member    │  │     Planning        │ │
│  │ Management  │  │ Management  │  │    Services         │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ Invitation  │  │ Permission  │  │     Phase           │ │
│  │   System    │  │   System    │  │   Management        │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**Components:**
- **Trip Management**: CRUD operations, lifecycle management
- **Member Management**: Role assignment, invitation handling
- **Planning Services**: Date finding, destination planning
- **Invitation System**: Email-based invitations, signup flow
- **Permission System**: Role-based access control
- **Phase Management**: Plan → Go → Reminisce transitions

### User Domain

```
┌─────────────────────────────────────────────────────────────┐
│                    User Domain                              │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │    User     │  │   Session   │  │     Profile         │ │
│  │   Model     │  │ Management  │  │   Management        │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐                         │
│  │   Password  │  │   Privacy   │                         │
│  │   System    │  │  Settings   │                         │
│  └─────────────┘  └─────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

### Expense Domain

```
┌─────────────────────────────────────────────────────────────┐
│                  Expense Domain                             │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   Expense   │  │  Splitting  │  │     Settlement      │ │
│  │ Management  │  │  Algorithms │  │     System          │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │  Currency   │  │   Balance   │  │     Payment         │ │
│  │  Handling   │  │ Calculation │  │   Integration       │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Recipe Domain

```
┌─────────────────────────────────────────────────────────────┐
│                   Recipe Domain                             │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   Recipe    │  │ Ingredient  │  │    Shopping         │ │
│  │ Management  │  │   System    │  │  List Generator     │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │    Meal     │  │ Quantity    │  │     Purchase        │ │
│  │  Planning   │  │ Calculator  │  │    Tracking         │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┐
```

# Runtime View {#section-runtime-view}

## User Registration and Trip Invitation Flow

```
User A                    System                     User B
  |                         |                         |
  |-- Create Trip --------->|                         |
  |<-- Trip Created --------|                         |
  |                         |                         |
  |-- Invite User B ------->|                         |
  |                         |-- Send Email ---------->|
  |                         |                         |
  |                         |<-- Click Link ---------|
  |                         |                         |
  |                         |-- Show Signup -------->|
  |                         |<-- Register ------------|
  |                         |                         |
  |<-- User B Joined -------|-- Welcome Email ------>|
```

## Collaborative Date Planning

```
Participant A          System           Participant B
     |                    |                    |
     |-- Add Availability->|                   |
     |                    |-- Notify Others -->|
     |                    |<-- Add Availability|
     |<-- Live Update -----|                   |
     |                    |                   |
     |-- Propose Dates ---->|                   |
     |                    |-- Notify Others -->|
     |<-- Live Update -----|<-- Vote on Dates |
     |                    |-- Update Results->|
```

## Shopping List Aggregation

```
Recipe System     Shopping System     Purchase Tracking
      |                 |                      |
      |-- Ingredients -->|                     |
      |                 |-- Aggregate ------->|
      |                 |                     |
      |                 |<-- Manual Items ----|
      |                 |-- Combine Lists --->|
      |                 |                     |
      |                 |<-- Mark Purchased --|
      |                 |-- Update Status --->|
      |<-- Remaining----|                     |
```

# Deployment View {#section-deployment-view}

## Infrastructure Level 1 {#_infrastructure_level_1}

```
                    Internet
                       |
              ┌─────────────────┐
              │   Hetzner VPS   │
              │  Ubuntu 22.04   │
              │                 │
              │  ┌───────────┐  │
              │  │  Kamal 2  │  │
              │  │ Container │  │
              │  │ Manager   │  │
              │  └───────────┘  │
              │                 │
              │  ┌───────────┐  │
              │  │   Rails   │  │
              │  │    App    │  │
              │  │   +Puma   │  │
              │  └───────────┘  │
              │                 │
              │  ┌───────────┐  │
              │  │  SQLite/  │  │
              │  │PostgreSQL │  │
              │  └───────────┘  │
              │                 │
              │  ┌───────────┐  │
              │  │   File    │  │
              │  │ Storage   │  │
              │  └───────────┘  │
              └─────────────────┘
                       |
              ┌─────────────────┐
              │  Email Service  │
              │   (External)    │
              └─────────────────┘
```

**Deployment Motivation:**
- **Single Server**: Simplicity and cost-effectiveness for MVP
- **Containerized**: Consistent deployments via Kamal 2
- **Self-Hosted**: Independence from PaaS providers
- **Scalable Foundation**: Can add load balancer and additional servers later

**Quality Features:**
- **Reliability**: Automatic health checks and container restarts
- **Security**: HTTPS termination, firewall configuration
- **Performance**: Puma multi-threading, database connection pooling
- **Monitoring**: Application and system metrics collection

**Mapping of Building Blocks:**
- **Rails Application**: Runs in Docker container managed by Kamal
- **Database**: Local SQLite file or PostgreSQL container
- **File Storage**: Local filesystem with backup strategy
- **Background Jobs**: Solid Queue within Rails process
- **Cache**: Solid Cache using database storage

# Cross-cutting Concepts {#section-concepts}

## Security Concepts

**Authentication & Authorization**
- Rails 8 built-in authentication with secure session management
- Role-based access control (Owner, Co-Owner, Member, Guest)
- Password hashing with BCrypt
- CSRF protection enabled by default

**Data Protection**
- HTTPS enforcement in production
- Encrypted database connections
- Personal data anonymization options
- GDPR compliance measures

## User Experience Concepts

**Mobile-First Design**
- Touch-optimized interfaces
- Responsive breakpoints: mobile (320px+), tablet (768px+), desktop (1024px+)
- Progressive Web App features: installable, offline-capable
- Native app feel via Hotwire Native

**Progressive Enhancement**
- Core functionality works without JavaScript
- Enhanced interactions with Turbo and Stimulus
- Graceful degradation for older browsers

**Real-time Collaboration**
- Live updates via Turbo Streams over WebSockets
- Optimistic UI updates for immediate feedback
- Conflict resolution for simultaneous edits

## Development Concepts

**Code Organization**
- Domain-driven structure within Rails conventions
- Service objects for complex business logic
- ViewComponents for reusable UI elements
- Concerns for shared model/controller behavior

**Testing Strategy**
- Model tests: Unit tests for business logic
- Controller tests: Integration tests for HTTP endpoints
- System tests: End-to-end browser testing
- Component tests: ViewComponent testing

**Internationalization**
- Rails I18n framework
- German and English language support
- Locale detection and user preferences
- Translatable content management

## Operational Concepts

**Monitoring & Logging**
- Rails built-in logging with structured format
- Application performance monitoring
- Error tracking and notification
- Health check endpoints

**Backup & Recovery**
- Automated database backups
- File storage synchronization
- Point-in-time recovery capability
- Disaster recovery procedures

**Performance Optimization**
- Database indexing strategy
- Background job processing
- Asset pipeline optimization
- Caching strategy with Solid Cache

# Architecture Decisions {#section-design-decisions}

## ADR-001: Rails 8 over Next.js

**Status**: Accepted

**Context**: Previous attempts with Next.js were abandoned due to complexity and JavaScript ecosystem fatigue.

**Decision**: Use Ruby on Rails 8.0+ as the primary framework.

**Consequences**:
- ✅ Simplified development with Rails conventions
- ✅ Built-in solutions for authentication, background jobs, caching
- ✅ Excellent developer experience with Rails generators and tooling
- ❌ Less trendy than JavaScript frameworks
- ❌ Smaller talent pool for Ruby developers

## ADR-002: Hotwire over SPA Architecture

**Status**: Accepted

**Context**: Need for real-time collaboration without SPA complexity.

**Decision**: Use Hotwire (Turbo + Stimulus) for frontend interactivity.

**Consequences**:
- ✅ Server-rendered HTML for better SEO and performance
- ✅ Real-time updates via Turbo Streams
- ✅ Progressive enhancement principles
- ✅ Mobile app foundation with Hotwire Native
- ❌ Limited rich client-side interactions
- ❌ Learning curve for developers familiar with SPAs

## ADR-003: SQLite First, PostgreSQL Later

**Status**: Accepted

**Context**: Rails 8 Solid adapters make SQLite production-viable.

**Decision**: Start with SQLite, migrate to PostgreSQL when scaling needs require it.

**Consequences**:
- ✅ Simplified initial deployment
- ✅ No external database service required
- ✅ Rails 8 Solid adapters provide production features
- ❌ Limited concurrent write scalability
- ❌ Future migration effort required

## ADR-004: Single Server Deployment

**Status**: Accepted

**Context**: Cost optimization and operational simplicity for MVP.

**Decision**: Deploy to single Hetzner VPS with Kamal 2.

**Consequences**:
- ✅ Low operational overhead
- ✅ Cost-effective for small user base
- ✅ Kamal 2 provides easy deployment and management
- ❌ Single point of failure
- ❌ Scaling limitations

## ADR-005: Built-in Authentication over Devise

**Status**: Accepted

**Context**: Rails 8 includes authentication generator.

**Decision**: Use Rails 8 built-in authentication as foundation, extend as needed.

**Consequences**:
- ✅ Reduced dependencies
- ✅ Full control over authentication code
- ✅ Aligned with Rails 8 philosophy
- ❌ Need to implement advanced features manually
- ❌ Less battle-tested than Devise

# Quality Requirements {#section-quality-scenarios}

## Quality Tree

```
Quality
├── Usability
│   ├── Simplicity (Priority 1)
│   ├── Mobile Experience (Priority 3)
│   └── Accessibility
├── Functionality
│   ├── Collaboration (Priority 2)
│   ├── Data Integrity
│   └── Feature Completeness
├── Reliability
│   ├── Availability (Priority 5)
│   ├── Error Recovery
│   └── Data Safety
├── Performance
│   ├── Response Time (Priority 4)
│   ├── Throughput
│   └── Resource Usage
└── Maintainability
    ├── Code Quality
    ├── Testability
    └── Deployability
```

## Quality Scenarios

### Usability Scenarios

**UC-1: Simple Trip Creation**
- **Stimulus**: New user wants to create their first trip
- **Response**: System guides through trip creation in < 3 steps
- **Measure**: 90% of users complete trip creation without help

**UC-2: Mobile Shopping List**
- **Stimulus**: User checks shopping list while in grocery store
- **Response**: Mobile-optimized interface loads in < 2 seconds
- **Measure**: Touch targets are minimum 44px, readable text size

### Collaboration Scenarios

**CO-1: Real-time Updates**
- **Stimulus**: User A adds expense while User B views expense list
- **Response**: User B sees update within 5 seconds without refresh
- **Measure**: < 5 second latency for live updates

**CO-2: Concurrent Editing**
- **Stimulus**: Multiple users edit shopping list simultaneously
- **Response**: System prevents conflicts and preserves all data
- **Measure**: No data loss in concurrent editing scenarios

### Performance Scenarios

**PE-1: Page Load Time**
- **Stimulus**: User clicks navigation link on 3G connection
- **Response**: Page content visible within 2 seconds
- **Measure**: Time to First Contentful Paint < 2000ms

**PE-2: Background Processing**
- **Stimulus**: Complex expense calculation for 20 participants
- **Response**: Calculation completes without blocking UI
- **Measure**: Background jobs complete within 30 seconds

### Reliability Scenarios

**RE-1: Server Downtime**
- **Stimulus**: Server maintenance window of 30 minutes
- **Response**: Application returns to full functionality
- **Measure**: 99.5% uptime target (< 4 hours/month downtime)

**RE-2: Data Recovery**
- **Stimulus**: Database corruption detected
- **Response**: System restores from backup within 1 hour
- **Measure**: Recovery Point Objective (RPO) < 24 hours

# Risks and Technical Debts {#section-technical-risks}

## High Priority Risks

### R-1: Single Point of Failure (High Risk)
**Description**: Single server deployment creates availability risk
**Impact**: Complete service outage during server failures
**Probability**: Medium (server failures happen)
**Mitigation**: 
- Implement comprehensive monitoring
- Prepare load balancer + multi-server deployment plan
- Regular backup testing and recovery procedures

### R-2: SQLite Scaling Limitations (Medium Risk)
**Description**: SQLite may not handle concurrent users at scale
**Impact**: Performance degradation, potential data corruption
**Probability**: High (if successful)
**Mitigation**:
- Monitor database performance metrics
- Prepare PostgreSQL migration plan
- Implement connection pooling and query optimization

### R-3: Mobile Experience Complexity (Medium Risk)
**Description**: Hotwire Native mobile app development learning curve
**Impact**: Delayed mobile app delivery
**Probability**: Medium
**Mitigation**:
- Focus on PWA experience first
- Gradual Hotwire Native implementation
- Consider hybrid alternatives if needed

## Medium Priority Risks

### R-4: Email Deliverability (Medium Risk)
**Description**: Invitation emails marked as spam
**Impact**: Users cannot join trips via email invitations
**Mitigation**:
- Use reputable email service provider
- Implement SPF, DKIM, DMARC records
- Alternative invitation methods (links, QR codes)

### R-5: Data Export/Import Complexity (Low Risk)
**Description**: Recipe and trip data reuse features complex to implement
**Impact**: Reduced user value, manual data re-entry
**Mitigation**:
- Start with simple CSV export/import
- Iteratively improve data migration tools
- Focus on core features first

## Technical Debts

### TD-1: Authentication Extension
**Current**: Basic Rails 8 authentication
**Debt**: Missing advanced features (2FA, OAuth, account recovery)
**Timeline**: Address in Phase 2

### TD-2: Testing Coverage
**Current**: Basic model and integration tests
**Debt**: Comprehensive system tests, performance tests
**Timeline**: Ongoing throughout development

### TD-3: Monitoring and Observability
**Current**: Basic Rails logging
**Debt**: Structured logging, metrics, alerting
**Timeline**: Before production deployment

# Glossary {#section-glossary}

| Term | Definition |
|------|------------|
| **Trip** | A planned group activity with defined participants, dates, and activities |
| **Trip Owner** | User who created the trip with full administrative rights |
| **Co-Owner** | User with administrative rights similar to owner, but cannot delete trip |
| **Member** | Regular trip participant with planning permissions |
| **Guest** | Read-only trip participant without editing permissions |
| **Phase** | Trip lifecycle stage: Plan (before), Go (during), Reminisce (after) |
| **Availability** | User's indication of free/busy time for potential trip dates |
| **Proposal** | Suggested trip element (dates, destinations) for group decision |
| **Recipe** | Meal preparation instructions with ingredient lists |
| **Shopping List** | Aggregated list of items needed for trip |
| **Expense Split** | Algorithm for dividing costs among participants |
| **Settlement** | Final payment transfers to balance expenses |
| **Solid Adapters** | Rails 8 database-backed alternatives to Redis (Cache, Queue, Cable) |
| **Hotwire** | Frontend framework combining Turbo and Stimulus for Rails |
| **Kamal** | Rails deployment tool for containerized applications |

---

*This architecture documentation serves as the living guide for PlanGoReminisce development and will be updated as the system evolves.*