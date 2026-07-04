# API Documentation for WhatsApp Mobile App Backend

This document describes the main REST API endpoints for the WhatsApp mobile app backend, built with FastAPI.

## Endpoints

### 1. Root
- **GET /**
- **Description:** Health check endpoint.
- **Response:**
  - 200 OK: `{ "message": "FastAPI is running" }`

---



### 2. Get All persona
- **GET /all-persona**
- **Description:** Get a paginated list of all persona.
- **Query Parameters:**
  - `limit` (int, optional, default=50): Number of persona to return
  - `offset` (int, optional, default=0): Pagination offset
- **Response:**
  - 200 OK: List of Persona objects

#### Persona Object
- `id` (int)
- `name` (string)
- `desc` (string)
- `image_url` (string)

---

### 3. Search persona
- **GET /search-personas/{query}**
- **Description:** Search for persona by name or keyword.
- **Path Parameter:**
  - `query` (string): Search term
- **Response:**
  - 200 OK: List of Persona objects

---

### 4. Get persona User Chatted With
- **GET /personas/{user_id}**
- **Description:** Get a list of persona a user has chatted with.
- **Path Parameter:**
  - `user_id` (int): User ID
- **Response:**
  - 200 OK: List of Persona objects

---

### 5. Get Messages Between Users
- **GET /messages**
- **Description:** Get messages exchanged between two users.
- **Query Parameters:**
  - `sender_id` (int): Sender user ID
  - `receiver_id` (int): Receiver user ID
  - `limit` (int, optional, default=50): Number of messages to return
  - `offset` (int, optional, default=0): Pagination offset
- **Response:**
  - 200 OK: List of Message objects

#### Message Object
- `id` (int)
- `sender_id` (int)
- `receiver_id` (int)
- `text` (string)
- `image_object_name` (string, optional)

---

### 6. Get All Challenges
- **GET /challenges**
- **Description:** Get a list of all challenges, each with its context.
- **Response:**
  - 200 OK: List of Challenge objects

#### Challenge Object
- `id` (string)
- `title` (string)
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

### 7. Create or Update Challenge
- **POST /challenges**
- **Description:** Create a new challenge or update an existing one.
- **Request Body:** ChallengeCreate object
- **Response:**
  - 200 OK: Challenge object

---


### 8. Setup Challenge (Start/Resume)
- **POST /setup_challenge**
- **Description:** Start or resume a challenge for a user with a selected Persona. If a session exists, resumes it; otherwise, assigns Persona and generates storyline.
- **Request Body:** ChallengeSetup object
- **Response:**
  - 200 OK: ChallengeSetupResponse object

#### ChallengeSetup Object
- `challenge_id` (string): The challenge to start
- `persona_id` (int, optional): The Persona to assign
- `user_id` (int): The user starting the challenge


#### ChallengeSetupResponse Object
- `message` (string): message
- `challenge_session_id` (int, optional): Session ID for the challenge
- `intro` (object, optional): StorylineResponse object
- `status` (string, optional): ChallengeResult status, see table below.
- `total_duration_minutes` (int, optional): Total duration of the challenge session in minutes
- `conversation_history` (array of Message objects, optional): The full conversation history for the current challenge session. Each item is a Message object as described below.

---

## ChallengeResult Values

| Value                     | Description                                             |
| ------------------------- | ------------------------------------------------------- |
| `won`                     | Challenge completed successfully.                       |
| `won_objective_completed` | Persona agreed to or completed the challenge objective. |
| `lost_timeout`            | Challenge failed due to timeout or inactivity.          |
| `lost_rejected`           | Persona explicitly rejected the challenge objective.    |
| `lost_blocked`            | Persona became angry or blocked the user.               |
| `lost_rule_violation`     | User violated challenge rules or restrictions.          |
| `abandoned`               | Challenge was abandoned before completion.              |
| `active`                  | Challenge is currently active and ongoing.              |

---

## Notes

* `WON` is a generic success state.
* `WON_OBJECTIVE_COMPLETED` is a more specific success outcome indicating the objective was explicitly accepted or completed.
* `ACTIVE` indicates the challenge is still in progress.
* `ABANDONED` is neither a win nor a loss state.


#### StorylineResponse Object
- `storyline` (string): The intro story with dynamic pauses like [pause: 1.0]
- `call_to_action` (string): A clear, short instruction telling the user what to do next

#### Message Object
- `id` (int): Message ID
- `sender_id` (int): Sender user ID
- `receiver_id` (int): Receiver user ID
- `text` (string): Message text
- `image_object_name` (string, optional): Name of the image object if present
- `challenge_session_id` (int, optional): Challenge session ID if message is part of a challenge

### 9. Get Challenge Attempts
- **GET /challenge-attempts/{challenge_id}**
- **Description:** Get all attempts for a given challenge.
- **Path Parameter:**
  - `challenge_id` (string): Challenge ID
- **Response:**
  - 200 OK: List of ChallengeAttempt objects

#### ChallengeAttempt Object
- `id` (UUID)
- `challenge_id` (string)
- `user_id` (int)
- `persona_id` (int)
- `role_mode` (string, optional)
- `won` (bool)
- `time_taken_seconds` (int, optional)
- `attempt_number` (int, optional)
- `created_at` (string, datetime)

---



## Real-Time Messaging (Socket.IO)
- **Socket.IO endpoint:** `/socket.io`
- Used for real-time messaging and challenge session management. Main events:
  - `connect`: Client connects to the server
  - `disconnect`: Client disconnects
  - `join`: Register a user session (`{ user_id }`)
  - `join_challenge`: Join a challenge room (`{ challenge_session_id }`)
  - `send_message`: Send a chat message (`{ sender_id, receiver_id, text, challenge_session_id, image_object_name? }`)
  - `receive_message`: Receive messages (including AI responses)
  - `challenge_update`: (Emitted by server) Notifies clients in a challenge room about challenge status updates. See ChallengeCompletion object below.
- Rooms are used for challenge sessions: `challenge:<challenge_session_id>`
- All events are asynchronous. See `app/socketio_server.py` and `app/socketio_server_events.md` for full event details and payloads.

---



---

### ChallengeCompletion Object (for challenge_update event)
- `reason` (string, optional): Reason for challenge completion or status change
- `challenge_status` (string): Status of the challenge (e.g., "COMPLETED", "FAILED", "ACTIVE")
- `challenge_session_id` (int): The session ID for the challenge
- `user_id` (int): The user who completed or is involved in the challenge
- `challenge_id` (int): The challenge ID

---

## Notes
- All endpoints return JSON responses.
- CORS is enabled for all origins.
- For authentication and additional endpoints, see this documentation for all request and response formats.
