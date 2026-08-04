# Backend Integration Tasks: Premium Onboarding Flow

This document lists requirements and recommended additions for the backend to support the next iteration of the premium onboarding flow.

---

## 1. Interest-Based Category Filtering
- **Endpoint**: `GET /all-persona` (or `GET /personas`)
- **Requirement**: Allow passing a list of category filters (e.g. `?interests=Entrepreneurship,Technology`).
- **Behavior**: Return only AI personas matching the requested categories.
- **Fallback**: If no interests are provided, return the full paginated list as it works today.

---

## 2. Recommendation & Personalization Engine
- **Endpoint**: `GET /personas/recommended` [NEW]
- **Requirement**: A dedicated recommendations endpoint that calculates score weights for personas based on user interest tags, chat history frequency, and active session dynamics.

---

## 3. Immersion Greeting Overrides
- **Requirement**: Implement a flag or endpoint parameter to fetch a greeting override matching the onboarding persona selected.
- **Behavior**: Instead of standard greetings (e.g., "Hello, how can I help you today?"), the backend should support delivering a thought-provoking introductory message (e.g. Steve Jobs: "Everyone says they want to build something extraordinary. Very few are willing to sacrifice for it. Which one are you?").

---

## 4. Delayed Authentication Support
- **Requirement**: Allow anonymous session creation for the first few messages in a persona fork.
- **Behavior**: Support generating temporary user tokens that can be merged/migrated into a real user profile during subsequent Google Sign-In authentication checks.
