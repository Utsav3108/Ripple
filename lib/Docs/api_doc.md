# API Documentation for Ripple Backend (FastAPI)

This document describes the REST API endpoints and real-time Socket.IO protocols for the Ripple mobile app backend built with FastAPI.

---

## Authentication & Security

All REST endpoints except the **Root** (`/`) and **Google Login** (`/auth/google`) endpoints require a valid Google `idToken` to be supplied as a Bearer token in the `Authorization` header:

```http
Authorization: Bearer <google_id_token>
```

The token is verified securely against Google's OAuth2 APIs. Upon validation:
- The backend matches the verified Google profile (`name`, `email`, `picture`) against a database `Persona`.
- If the persona does not exist, a new human persona is created (`is_human=True`).
- Unauthenticated requests to protected endpoints return `401 Unauthorized`.
- Attempting to access or mutate resources belonging to another user ID (such as checking another user's chat history or attempting a challenge on their behalf) returns `403 Forbidden`.

---

## Endpoints

### 1. Root (Public)
- **GET /**
- **Description:** Health check endpoint to verify backend status.
- **Response:**
  - `200 OK`: `{ "message": "FastAPI is running" }`

---

### 2. Google Login (Public)
- **POST /auth/google**
- **Description:** Authenticate, register, or login a user using a Google OAuth2 ID Token.
- **Request Body:**
  ```json
  {
    "id_token": "string"
  }
  ```
- **Response:**
  - `200 OK`: Returns the created or logged-in user's [Persona Object](#persona-object).
  - `400 Bad Request`: Validation failure if the Google ID token is invalid or expired.

---

### 3. Get All Personas (Protected)
- **GET /all-persona**
- **Description:** Get a paginated list of all personas in the database.
- **Query Parameters:**
  - `limit` (int, optional, default=50): Number of personas to return.
  - `offset` (int, optional, default=0): Pagination offset.
- **Response:**
  - `200 OK`: List of [Persona Objects](#persona-object).

#### Persona Object
- `id` (int): Unique identifier.
- `name` (string): Persona name.
- `desc` (string): Description of the persona.
- `image_url` (string): URL to their profile picture.
- `traits` (string, optional): Key traits or behaviors.
- `is_human` (bool): Indicates if the persona represents a genuine human user or an AI.

---

### 4. Search Personas (Protected)
- **GET /search-personas/{query}**
- **Description:** Search for personas by name or keyword traits.
- **Path Parameter:**
  - `query` (string): Search term.
- **Response:**
  - `200 OK`: List of [Persona Objects](#persona-object).

---

### 5. Get Personas User Chatted With (Protected)
- **GET /personas/{user_id}**
- **Description:** Get a list of personas the authenticated user has active chats with.
- **Path Parameter:**
  - `user_id` (int): User ID. Must match the authenticated `current_user.id`.
- **Response:**
  - `200 OK`: List of [Persona Objects](#persona-object).
  - `403 Forbidden`: If `user_id` does not match the authenticated user.

---

### 6. Get Persona Details (Protected)
- **GET /personas/{persona_id}/details**
- **Description:** Static profile info for a persona details page — no emotional/session state. AI personas only.
- **Path Parameter:**
  - `persona_id` (int): The AI persona to fetch.
- **Response:**
  - `200 OK`: [Persona Details Object](#persona-details-object).
  - `404 Not Found`: If `persona_id` doesn't exist, or resolves to a human persona.

#### Persona Details Object
- `name` (string)
- `desc` (string)
- `expertise` (list of string, optional): `null` if the persona's `traits` isn't a structured object (legacy free-text traits).
- `category` (string)
- `likes_dislikes` (object, optional): `{ "likes": [string], "dislikes": [string] }`, `null` under the same legacy-traits condition as `expertise`.

---

### 7. Get Persona Chats List (Protected)
- **GET /personas/{persona_id}/chats**
- **Description:** Every chat (session/fork) the authenticated user has ever had with this persona, including blocked ones, each tagged with a status. No message previews — list only.
- **Path Parameter:**
  - `persona_id` (int): The AI persona. Chats are always scoped to `current_user.id` as the human side of the pair — there is no way to list another user's chats.
- **Query Parameters:**
  - `page` (int, optional, default=1, min=1)
  - `limit` (int, optional, default=20, min=1, max=100)
- **Response:**
  - `200 OK`: [Persona Chats Response Object](#persona-chats-response-object).
  - `404 Not Found`: If `persona_id` doesn't exist, or resolves to a human persona.

#### Persona Chats Response Object
- `chats` (array of [Persona Chat Objects](#persona-chat-object))
- `page` (int)
- `limit` (int)
- `total_count` (int)
- `total_pages` (int)
- `has_more` (bool)

#### Persona Chat Object
- `persona_session_id` (int)
- `status` (string: `"recent"`, `"active"`, or `"blocked"`): Exactly one chat across all of the user's sessions with this persona is `"recent"` — the one with the latest `last_updated_at`, even if that session is also currently blocked (recent overrides blocked). Every other session is `"blocked"` if currently blocked, otherwise `"active"`.
- `last_updated_at` (string, datetime)

---

### 8. Create New Persona Session (Protected)
- **POST /persona-sessions/new**
- **Description:** Explicitly starts a brand-new persona session (fork) with baseline emotional state for the given persona, ignoring any existing fork for the pair — including a currently-blocked one. Not needed for normal chat: `send_message` (Socket.IO) already creates a session lazily on a pair's first-ever message. Use this only for an explicit user-initiated fresh start, e.g. after receiving a `persona_blocked` Socket.IO event and the user chooses to start over rather than wait for `check_unblock_status` to clear. See `/docs/socketio_server_events.md` for the block/unblock event flow.
- **Request Body:**
  - `persona_id` (int): The AI persona to start a fresh session with.
- **Response:**
  - `200 OK`: `{ "persona_session_id": int }` — the new session's ID. The new fork immediately becomes the active session for this pair; subsequent messages to this persona will use it.

---

### 9. Get Messages Between Users (Protected)
- **GET /messages**
- **Description:** Retrieve chat history between the current user and another persona.
- **Query Parameters:**
  - `sender_id` (int): Sender user ID. Must match the authenticated `current_user.id`.
  - `receiver_id` (int): Receiver persona ID.
  - `limit` (int, optional, default=50): Number of messages to return.
  - `offset` (int, optional, default=0): Pagination offset.
- **Response:**
  - `200 OK`: List of Message objects.
  - `403 Forbidden`: If `sender_id` does not match the authenticated user.

#### Message Object
- `id` (int)
- `sender_id` (int)
- `receiver_id` (int)
- `text` (string)
- `image_object_name` (string, optional)
- `challenge_session_id` (int, optional)
- `persona_session_id` (int, optional): The persona session (fork) this message belongs to. Set for regular persona chat, `null` for challenge messages.

---

### 10. Get Conversations (Paginated) (Protected)
- **GET /conversations**
- **Description:** Paginated message history. Exactly one of the four discriminators below must be provided; the endpoint returns `422 Unprocessable Entity` if none is given. Ordered chronologically (oldest first within the page).
- **Query Parameters:**
  - `page` (int, optional, default=1, min=1): Page number, 1-indexed.
  - `page_size` (int, optional, default=10, min=1, max=100): Messages per page.
  - `sender_id` + `receiver_id` (int, both required together): All regular persona-chat messages between this pair, across every `persona_session_id` fork mixed together. `current_user.id` must be one of the two, or `403 Forbidden`.
  - `persona_session_id` (int): Messages for one specific fork of a persona chat only — use this instead of `sender_id`/`receiver_id` to see just the active (or a specific past) session's history, e.g. after starting a fresh session via `POST /persona-sessions/new` (endpoint 8). Scoped to the requesting user automatically (must be sender or receiver on the matching rows); a non-participant querying another user's `persona_session_id` gets an empty page back, not an error.
  - `challenge_session_id` (int): Messages for an ongoing challenge session.
  - `attempt_session_id` (int): Messages for a past completed challenge attempt (same underlying lookup as `challenge_session_id`).
- **Response:**
  - `200 OK`: [Paginated Messages Response](#paginated-messages-response-object).
  - `403 Forbidden`: If using `sender_id`/`receiver_id` and `current_user.id` is neither.
  - `422 Unprocessable Entity`: If none of the four discriminators is provided.

#### Paginated Messages Response Object
- `messages` (array of [Message Objects](#message-object))
- `page` (int)
- `page_size` (int)
- `total_count` (int)
- `total_pages` (int)
- `has_more` (bool)

---

### 11. Get All Challenges (Protected)
- **GET /challenges**
- **Description:** Get a list of all active challenges, each with its associated configuration and story context.
- **Response:**
  - `200 OK`: List of [Challenge Objects](#challenge-object).

#### Challenge Object
- `id` (string): Unique challenge string identifier.
- `title` (string): Title of the challenge.
- `subtitle` (string, optional)
- `description` (string, optional)
- `short_description` (string, optional)
- `categories` (list of string, optional)
- `suggested_personas` (list of int, optional)
- `difficulty` (string, optional: "beginner", "intermediate", "advance")
- `difficulty_settings` (dict, optional)
- `estimated_duration_minutes` (int, optional)
- `challenge_rules` (dict, optional)
- `image_url` (string, optional)
- `selected_persona_id` (int, optional)
- `context` (ChallengeContext object, optional)

#### ChallengeContext Object
- `id` (int)
- `challenge_id` (string)
- `setting` (string)
- `environment` (object, optional)
- `goal` (string)
- `stakes` (string)
- `platform` (string)

---

### 12. Create or Update Challenge (Protected)
- **POST /challenges**
- **Description:** Create a new challenge configuration or update an existing one.
- **Request Body:** ChallengeCreate object
- **Response:**
  - `200 OK`: [Challenge Object](#challenge-object).

---

### 13. Setup Challenge (Protected)
- **POST /setup_challenge**
- **Description:** Start or resume a challenge session with a selected AI persona. If a session is active, returns the existing context; otherwise, assigns the persona and generates the starting storyline.
- **Request Body:**
  - `challenge_id` (string): The challenge to start.
  - `user_id` (int): The user ID. Must match the authenticated `current_user.id`.
  - `persona_id` (int, optional): Persona to assign.
  - `attempt_session_id` (int, optional): Links to a specific previous attempt session if retrieving logs.
- **Response:**
  - `200 OK`: ChallengeSetupResponse object.
  - `403 Forbidden`: If `user_id` does not match the authenticated user.

#### ChallengeSetupResponse Object
- `message` (string)
- `challenge_session_id` (int, optional): Unique session ID.
- `intro` (StorylineResponse object, optional): Contains `storyline` and `call_to_action`.
- `status` (string, optional): Current challenge state (e.g. `active`, `won`, `lost_rejected`).
- `total_duration_minutes` (int, optional)
- `conversation_history` (array of Message objects, optional)

---

### 14. Get Challenge Attempts (Protected)
- **GET /challenge-attempts/{challenge_id}**
- **Description:** Get the attempt history of the **currently authenticated user** for the specified challenge. Attempts by other users are excluded.
- **Path Parameter:**
  - `challenge_id` (string): Challenge ID.
- **Response:**
  - `200 OK`: List of ChallengeAttempt objects.

#### ChallengeAttempt Object
- `id` (UUID): Unique attempt ID.
- `challenge_id` (string)
- `user_id` (int): User ID.
- `persona_id` (int): Target AI persona.
- `role_mode` (string, optional)
- `won` (bool): Win outcome flag.
- `time_taken_seconds` (int, optional)
- `attempt_number` (int, optional)
- `created_at` (string, datetime)

---

## Admin Endpoints

All routes below are mounted under the `/admin` prefix and require the authenticated `Persona` (same Google `idToken` Bearer auth described in [Authentication & Security](#authentication--security)) to have `is_admin=true`. Non-admin callers receive `403 Forbidden`. There is no bootstrap endpoint to grant the first admin — that's a one-off direct database change.

`challenge_sessions` admin visibility is explicitly out of scope for this pass — these endpoints only cover regular persona chat (`PersonaSession`) and the AI persona roster.

### Admin 1. List Persona Session Pairs (Admin)
- **GET /admin/persona-sessions**
- **Description:** Grouped-by-pair list of persona chat sessions — one row per `(ai_persona_id, human_persona_id)` pair, aggregated across all forks (concurrent sessions) for that pair.
- **Query Parameters:**
  - `ai_persona_id` (int, optional): Exact-match filter on the AI persona.
  - `human_persona_id` (int, optional): Exact-match filter on the human user.
  - `has_blocked_fork` (bool, optional): Filters to pairs where *any* fork is currently blocked (`true`) or none are (`false`).
  - `limit` (int, optional, default=50), `offset` (int, optional, default=0).
- **Response:**
  - `200 OK`: List of [Persona Session Pair Objects](#persona-session-pair-object), sorted by most recently updated fork first.

#### Persona Session Pair Object
- `ai_persona_id` (int)
- `ai_persona_name` (string)
- `human_persona_id` (int)
- `human_persona_name` (string)
- `fork_count` (int): Number of concurrent session rows for this pair.
- `any_fork_blocked` (bool): `true` if any fork for this pair currently has `is_blocked=true`.
- `latest_updated_at` (string, datetime): Most recent `updated_at` across all forks.

---

### Admin 2. List Forks For a Pair (Admin)
- **GET /admin/persona-sessions/pairs/{ai_persona_id}/{human_persona_id}/forks**
- **Description:** Expands a pair from the grouped list into its individual fork rows.
- **Path Parameters:**
  - `ai_persona_id` (int), `human_persona_id` (int)
- **Response:**
  - `200 OK`: List of [Persona Session Fork Objects](#persona-session-fork-object), sorted by `updated_at` descending.

#### Persona Session Fork Object
- `id` (int): Fork's `persona_sessions.id`.
- `is_blocked` (bool)
- `block_reason` (string, optional)
- `turn_count` (int)
- `created_at` (string, datetime)
- `updated_at` (string, datetime)

---

### Admin 3. Get Persona Session Detail (Admin)
- **GET /admin/persona-sessions/{session_id}**
- **Description:** Full emotional state row for a single fork, plus the count of chat messages linked to it.
- **Path Parameter:**
  - `session_id` (int)
- **Response:**
  - `200 OK`: [Persona Session Detail Object](#persona-session-detail-object).
  - `404 Not Found`: If no session with that id exists.

#### Persona Session Detail Object
- `id`, `ai_persona_id`, `human_persona_id` (int)
- `arousal`, `patience`, `mood`, `rapport`, `curiosity` (float)
- `last_subject` (string, optional)
- `topic_repeat_streak`, `turn_count`, `violation_count` (int)
- `is_blocked` (bool), `block_reason` (string, optional)
- `created_at`, `updated_at` (string, datetime)
- `linked_message_count` (int): Count of `messages` rows with this `persona_session_id`.

---

### Admin 4. Reset Persona Session Block (Admin)
- **POST /admin/persona-sessions/{session_id}/reset-block**
- **Description:** Clears `is_blocked`, `block_reason`, and `violation_count` on a fork. Safe to call on an already-unblocked fork (idempotent). Writes an entry to the admin audit log with the admin's id and the fork's prior state.
- **Path Parameter:**
  - `session_id` (int)
- **Response:**
  - `200 OK`: `{ "id": int, "is_blocked": false, "block_reason": null, "violation_count": 0 }`
  - `404 Not Found`: If no session with that id exists.

---

### Admin 5. List Personas (Admin)
- **GET /admin/personas**
- **Description:** List AI personas (human user accounts are excluded, matching `/all-persona`'s convention).
- **Query Parameters:**
  - `name` (string, optional): Case-insensitive substring search.
  - `active_only` (bool, optional): Filter by `is_active`.
  - `limit` (int, optional, default=50), `offset` (int, optional, default=0).
- **Response:**
  - `200 OK`: List of `{ "id", "name", "image_url", "is_active" }`.

---

### Admin 6. Get Persona (Admin)
- **GET /admin/personas/{persona_id}**
- **Description:** Full persona object including `is_active`/`is_admin` and structured `traits` (identity, personality sliders, `interests_expertise`, `likes_dislikes`, brain profile, etc.).
- **Response:**
  - `200 OK`: [Admin Persona Object](#admin-persona-object).
  - `404 Not Found`

#### Admin Persona Object
All fields of the existing [Persona Object](#persona-object), plus:
- `is_active` (bool)
- `is_admin` (bool)

---

### Admin 7. Create Persona (Admin)
- **POST /admin/personas**
- **Description:** Creates a new AI persona (`is_human` is always `false`).
- **Request Body:** `name`, `desc`, `traits`, `image_url` (required); `category`, `email`, `role`, `bio`, `settings`, `is_active` (optional, `is_active` defaults `true`). The 5 `traits.brain` floats (`threat_sensitivity`, `self_regulation`, `novelty_drive`, `baseline_security`, `empathic_resonance`) must each be within `0.0`–`100.0`.
- **Response:**
  - `200 OK`: [Admin Persona Object](#admin-persona-object).
  - `422 Unprocessable Entity`: If a brain trait float is out of bounds.

---

### Admin 8. Update Persona (Admin)
- **PUT /admin/personas/{persona_id}**
- **Description:** Partial update — only fields present in the request body are changed (matches the existing `PUT /profile` semantics). Can grant or revoke `is_admin` on the target persona.
- **Request Body:** Any subset of `name`, `desc`, `traits`, `image_url`, `category`, `bio`, `settings`, `is_active`, `is_admin`.
- **Response:**
  - `200 OK`: [Admin Persona Object](#admin-persona-object).
  - `404 Not Found`

---

### Admin 9. Delete Persona (Admin)
- **DELETE /admin/personas/{persona_id}**
- **Description:** Soft-delete — sets `is_active=false`; the row is not removed (avoids orphaning `persona_sessions`/`messages` foreign keys, which have no cascade defined). Writes an entry to the admin audit log.
- **Response:**
  - `200 OK`: [Admin Persona Object](#admin-persona-object) with `is_active=false`.
  - `404 Not Found`

---

## Real-Time Messaging (Socket.IO)

- **Socket.IO Endpoint:** `/socket.io`
- Protocol events, room joining, and server events remain unchanged. Refer to [socketio_server_events.md](file:///Users/utsav/Documents/Projects/WhatsApp/app/docs/socketio_server_events.md) for Socket.IO API schemas.
