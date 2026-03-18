# EduViz 🎓

### Interactive Physics & Mathematics Visualizations for School Students

<!-- Badges -->
<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

**Live Demo**: [eduviz-a3234.web.app](https://eduviz-a3234.web.app)

</div>

---

## ✨ Features

### 📚 Subject Catalog
Browse organized Physics, Mathematics, and Chemistry topics tailored for your class level (6-12).

### 🎮 Interactive Simulations
Hands-on, real-time physics and math visualizations:
- **Projectile Motion** - Launch angles, velocity, gravity effects
- **Waves & SHM** - Sine/cosine waves with superposition
- **Electric Circuits** - Series & parallel circuit builder
- **Gravitation & Orbits** - Sun-planet-moon orbital mechanics
- **Newton's Laws** - Force and motion with free body diagrams
- **Fluid Pressure** - Buoyancy and floating/sinking physics
- **Linear Equations** - Graph lines and find intersections
- **Geometry** - Triangle, circle, rectangle area calculations
- **Atomic Structure** - Bohr model with electron shells (elements 1-18)
- **Acids & Bases** - Interactive pH scale and titration

### 🤖 AI Tutor
Get instant explanations for any topic with:
- Voice input (speech-to-text)
- Text-to-speech in English or Telugu
- AI-powered concept explanations


### 🌐 Multi-Language Support
Content and AI explanations available in English and Telugu.

---

## 🛠️ Tech Stack

### Frontend
| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter | ≥3.0.0 | Cross-platform UI framework |
| Riverpod | ^2.5.1 | State management |
| Dio | ^5.4.3 | HTTP client |
| fl_chart | ^0.68.0 | Charts & graphs |
| speech_to_text | ^6.6.0 | Voice input |
| flutter_tts | ^4.0.2 | Text-to-speech |
| shared_preferences | ^2.2.3 | Local storage |

### Backend
| Technology | Purpose |
|------------|---------|
| FastAPI | Python web framework |
| PostgreSQL | Primary database |
| Redis | Caching layer |
| OpenRouter | AI/LLM integration |

### Infrastructure
| Service | Purpose |
|---------|---------|
| Firebase Hosting | Frontend deployment |
| Render | Backend hosting |

---

## 📁 Project Structure

```
visual-learning-platform/
│
├── frontend/                    # Flutter Application
│   ├── lib/
│   │   ├── main.dart           # App entry point
│   │   ├── config/
│   │   │   └── app_config.dart # Configuration & constants
│   │   ├── models/
│   │   │   ├── concept.dart    # Data models
│   │   │   └── compute_result.dart
│   │   ├── providers/
│   │   │   └── compute_provider.dart
│   │   ├── screens/            # All application screens
│   │   │   ├── class_selection_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── topic_list_screen.dart
│   │   │   ├── concept_screen.dart
│   │   │   ├── history_screen.dart
│   │   │   ├── ai_assistant_screen.dart
│   │   │   ├── projectile_motion_screen.dart
│   │   │   ├── waves_screen.dart
│   │   │   ├── electric_circuits_screen.dart
│   │   │   ├── gravitation_orbits_screen.dart
│   │   │   ├── newtons_laws_screen.dart
│   │   │   ├── fluid_pressure_screen.dart
│   │   │   ├── linear_equations_screen.dart
│   │   │   ├── geometry_screen.dart
│   │   │   ├── atomic_structure_screen.dart
│   │   │   ├── acids_bases_screen.dart
│   │   │   └── sim_widgets.dart
│   │   ├── services/
│   │   │   ├── api_service.dart
│   │   │   └── ai_service.dart
│   │   └── widgets/
│   │       ├── ai_explanation_dialog.dart
│   │       ├── animation_canvas.dart
│   │       ├── graph_widget.dart
│   │       ├── slider_panel.dart
│   │       └── result_panel.dart
│   ├── pubspec.yaml
│   └── firebase.json
│
├── backend/                    # FastAPI Backend
│   ├── main.py
│   ├── routes/
│   ├── schemas/
│   ├── services/
│   └── seed/
│
└── .env.example
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.0.0+
- Python 3.9+
- PostgreSQL
- Redis


## 📡 API Reference

### Base URL
```
https://eduviz-backend-xm7b.onrender.com
```

### Endpoints

#### Simulations

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/simulations` | Fetch all available simulations |
| `POST` | `/simulations/projectile` | Run projectile motion |
| `POST` | `/simulations/waves` | Run wave simulation |
| `POST` | `/simulations/waves/superposition` | Wave superposition |
| `POST` | `/simulations/circuits` | Circuit analysis |

#### Run History

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/runs/save` | Save a simulation run |
| `GET` | `/runs` | Get user's run history |
| `GET` | `/runs/stats` | Get run statistics |

#### AI Assistant

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/ai/explain` | Get topic explanation |
| `POST` | `/ai/ask` | Ask a question |

### Headers
```http
X-Session-ID: <session_id>
Content-Type: application/json
```

---

## 🎨 Screens

| Screen | Route | Description |
|--------|-------|-------------|
| Class Selection | `/class-selection` | Choose class level (6-12) |
| Home | `/home` | Subject dashboard |
| Topic List | `/topic-list` | Browse topics |
| Simulation | `/simulation/:slug` | Interactive visualization |
| History | `/history` | Saved experiments |
| AI Assistant | `/ai-assistant` | Voice-powered tutor |

---

## 🎯 Application Flow

```
┌──────────────────┐
│  Class Selection │  ← Select your class (6-12)
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   Home Screen    │  ← Choose subject
│  Physics | Maths │    Physics/Maths/Chemistry
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   Topic List     │  ← Select topic
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   Simulation     │  ← Interactive visualization
│   Parameters     │    Adjust sliders & run
└────────┬─────────┘
         │
         ├──▶ View Results & Graphs
         │
         ├──▶ 🤖 AI Tutor ──▶ 📢 Text-to-Speech
         │
         └──▶ 💾 Save to History
```

---

## 🎨 Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Primary Blue | `#378ADD` | Buttons, accents |
| Background | `#0F0F18` | App background |
| Surface | `#1A1A24` | Cards, panels |
| Success Green | `#1D9E75` | Success states |
| Warning Amber | `#EF9F27` | Warnings |
| AI Purple | `#9C27B0` | AI features |
| Error Red | `#E24B4A` | Errors |

---