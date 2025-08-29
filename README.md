# PlanGoReminisce 🎒✈️

**Plan. Go. Reminisce.** - A collaborative trip planning application that transforms the typically solo effort of trip planning into a shared, enjoyable experience among friends.

## Overview

PlanGoReminisce supports you throughout the entire trip lifecycle:
- **Plan** (before): Coordinate dates, destinations, meals, expenses, and packing
- **Go** (during): Mobile-optimized companion for expense tracking and shopping
- **Reminisce** (after): Preserve memories and learn from past trips

Built with Ruby on Rails 8, embracing the "No PaaS Required" philosophy for simple, self-hosted deployment.

## ✨ Features

### 🤝 Collaborative Planning
- **User Management**: Role-based permissions (Owner, Co-Owner, Member, Guest)
- **Date Coordination**: Availability calendars and collaborative date finding
- **Destination Planning**: Group discussion and decision support
- **Invitation System**: Email-based invitations with automatic signup flow

### 🍽️ Meal Planning & Shopping
- **Recipe Management**: Create, share, and reuse recipes across trips
- **Meal Scheduling**: Collaborative meal planning calendar
- **Smart Shopping Lists**: Automatically aggregated from recipes with manual additions
- **Store-Optimized Views**: Organized by categories for efficient shopping

### 💰 Expense Management
- **Comprehensive Tracking**: Log and categorize all trip expenses
- **Flexible Splitting**: Multiple algorithms for fair cost distribution
- **Settlement System**: Generate payment requests and optimize transfers
- **Currency Support**: Multi-currency handling

### 🎒 Packing & Items
- **Shared Item Lists**: Coordinate who brings what (speakers, tents, etc.)
- **Personal Packing Lists**: Private checklists with reusable templates
- **Item Assignment**: Allocate shared responsibilities among group members

### 📱 Mobile-First Experience
- **Progressive Web App**: Works seamlessly on all devices
- **Offline Capability**: Basic functionality available without internet
- **Real-time Collaboration**: Live updates via Hotwire/Turbo

## 🛠️ Technology Stack

**Modern Rails 8 Architecture**
- **Framework**: Ruby on Rails 8.0+ with built-in authentication
- **Frontend**: Hotwire (Turbo + Stimulus) with Tailwind CSS
- **Database**: SQLite (development) → PostgreSQL (production scaling)
- **Background Jobs**: Solid Queue (no Redis required)
- **Caching**: Solid Cache (database-backed)
- **WebSockets**: Solid Cable (database-backed)
- **Deployment**: Kamal 2 for containerized deployment
- **Mobile**: Hotwire Native foundation for future mobile apps

## 🚀 Getting Started

### Prerequisites
- Ruby 3.2+ (3.4.5 recommended)
- Rails 8.0+
- Node.js (for asset compilation)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/plangoreminisce.git
   cd plangoreminisce
   ```

2. **Install dependencies**
   ```bash
   bundle install
   npm install  # if using npm for any frontend dependencies
   ```

3. **Setup database**
   ```bash
   rails db:migrate
   rails db:seed
   ```

4. **Start development server**
   ```bash
   bin/dev  # Runs Rails server + Tailwind CSS compilation
   ```

5. **Visit the application**
   Open http://localhost:3000 in your browser

### First Steps
1. Create an account on the landing page
2. Create your first trip
3. Invite friends via email
4. Start planning collaboratively!

## 📖 Documentation

- **[Architecture Documentation](plangoreminisce-architecture.md)** - Complete arc42 documentation
- **[Deployment Guide](DEPLOYMENT.md)** - Production deployment with Kamal 2
- **[API Documentation](docs/api.md)** - API endpoints (when implemented)

## 🏗️ Development Roadmap

### Phase 1: Foundation ✅
- [x] Rails 8 application with Solid adapters
- [x] User authentication and profiles
- [x] Basic responsive UI with Tailwind
- [x] Kamal deployment configuration

### Phase 2: Core Planning (In Progress)
- [ ] Trip creation and management
- [ ] User invitation system
- [ ] Role-based permissions
- [ ] Date proposal and availability system

### Phase 3: Advanced Features
- [ ] Recipe management and meal planning
- [ ] Shopping list aggregation
- [ ] Expense tracking and splitting
- [ ] Item/packing lists

### Phase 4: Mobile & Polish
- [ ] Hotwire Native mobile app
- [ ] Offline capability
- [ ] Advanced expense algorithms
- [ ] Trip finalization and export

## 🧪 Testing

```bash
# Run the test suite
rails test

# Run system tests
rails test:system

# Run linting
bundle exec rubocop

# Security checks
bundle exec brakeman
```

## 🌐 Deployment

This application is designed for simple, single-server deployment using Kamal 2.

**Quick Deploy:**
```bash
# Configure your server details in config/deploy.yml
bin/kamal setup    # First time only
bin/kamal deploy   # Subsequent deployments
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions.

## 🏛️ Architecture Principles

- **Simplicity First**: Rails conventions over complex configurations
- **Progressive Enhancement**: Works without JavaScript, enhanced with it
- **Mobile-First**: All features designed for mobile use
- **Collaborative**: Real-time updates and conflict resolution
- **Self-Hosted**: No external service dependencies

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Ruby on Rails 8](https://rubyonrails.org/)
- Styled with [Tailwind CSS](https://tailwindcss.com/)
- Interactive with [Hotwire](https://hotwired.dev/)
- Deployed with [Kamal 2](https://kamal-deploy.org/)
- Architecture documented with [arc42](https://arc42.org/)

---

**Ready to turn your group trips from chaos into adventure?** 🗺️

Start planning your next trip collaboratively with PlanGoReminisce!
