# Mood-Cast 🎧

> **"Your Vibe, Your Rhythm."**  
> Mood-Cast is a premium, AI-powered music social experience that synchronizes your emotional state with the perfect soundtrack. Using advanced facial recognition and real-time social synchronization, it transforms how you discover and share music.

---

## ✨ Key Pillars

### 🤖 AI Mood Analysis
Harnessing the power of **Google ML Kit Face Detection**, Mood-Cast analyzes your facial expressions through a premium **Lens HUD UI**. 
- **Real-time Scanning**: High-fidelity animations with heart-rate simulation and haptic feedback.
- **Emotion Mapping**: Detects *Happy, Sad, Angry, and Natural* states to curate the perfect playlist.
- **Vibe Engine**: Provides mood-specific jokes, positive affirmations, and adaptive UI themes.

### 👥 The Tribe (Social Sync)
Music is better together. **The Tribe** protocol allows for real-time collaborative listening rooms.
- **DJ Protocol**: One leader (the DJ) controls the vibe; everyone else listens in perfect sync.
- **Sync Engine**: Firestore-backed real-time synchronization of play/pause/seek across all devices.
- **Democratic Flow**: A 50% majority skip-vote system ensures the Tribe always controls the rhythm.
- **Live Heartbeat**: Real-time member presence tracking with low-latency updates.

### 🎵 High-Fidelity Playback
Powered by a sophisticated custom audio engine built on `just_audio` and `youtube_explode_dart`.
- **YouTube Music Integration**: Stream millions of tracks directly from YT Music with manifest pre-warming.
- **Zero-Lag Replay**: Global stream info caching for instant playback resume.
- **Sleep & Fade**: Intelligent sleep timers with 5-second linear volume fade-outs.
- **Offline Ready**: Automatic fallback to local storage if tracks are downloaded.

### ☁️ Community & Metrics
- **Global Moodboard**: See what the world is feeling and contribute your current vibe.
- **Vibe Leaderboards**: Discover the top-voted tracks for every emotion.
- **Real-time Analytics**: Track your music journey with deep metrics integration.

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter (Dart) |
| **State Management** | ValueNotifier / BLoC patterns |
| **Backend** | Firebase (Auth, Firestore, Cloud Messaging) |
| **AI / ML** | Google ML Kit (Face Detection) |
| **Audio Engine** | `just_audio`, `audio_service`, `audio_session` |
| **Music Source** | YouTube Music API (`youtube_explode`, `ytmusicapi`) |
| **Services** | OpenWeatherMap, Geolocator, Shared Preferences |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.11.0`
- Firebase Project
- Google ML Kit enabled in Firebase Console

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/5h3ld0rr/Mood-Cast.git
   cd mood-cast
   ```

2. **Setup Environment Variables**
   Create a `.env` file in the root directory:
   ```env
   OPEN_WEATHER_API_KEY=your_api_key_here
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Firebase Setup**
   Ensure you have configured `firebase_options.dart` for your specific project.

5. **Run the App**
   ```bash
   flutter run
   ```

---

## 🎨 Design System
Mood-Cast utilizes a **Glassmorphic** design language with an adaptive color palette:
- **Happy**: Vibrant Purple (`#A855F7`)
- **Sad**: Deep Blue (`#3B82F6`)
- **Angry**: Electric Red (`#FF3B30`)
- **Natural**: Emerald Green (`#10B981`)

Typography is powered by **Google Fonts (Inter & Space Grotesk)** for a premium, modern feel.

*Built with ❤️ for music lovers who believe every mood deserves a masterpiece.*
