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
  - 200 OK: List of President objects

#### President Object
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
  - 200 OK: List of President objects

---

### 4. Get persona User Chatted With
- **GET /personas/{user_id}**
- **Description:** Get a list of persona a user has chatted with.
- **Path Parameter:**
  - `user_id` (int): User ID
- **Response:**
  - 200 OK: List of President objects

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
- **Description:** Start or resume a challenge for a user with a selected president. If a session exists, resumes it; otherwise, assigns president and generates storyline.
- **Request Body:** ChallengeSetup object
- **Response:**
  - 200 OK: ChallengeSetupResponse object

#### ChallengeSetup Object
- `challenge_id` (string): The challenge to start
- `persona_id` (int, optional): The president to assign
- `user_id` (int): The user starting the challenge

#### ChallengeSetupResponse Object
- `message` (string): Status message
- `challenge_session_id` (int, optional): Session ID
- `intro` (object, optional): Storyline object
- `status` (string, optional): ChallengeResult status
- `total_duration_minutes` (int, optional): Duration

# ChallengeResult Enum

Represents the possible outcomes or states of a challenge.

```python
class ChallengeResult(str, Enum):

    # -----------------------------
    # WIN CONDITIONS
    # -----------------------------
    WON = "won"

    # Persona agreed to challenge objective
    WON_OBJECTIVE_COMPLETED = "won_objective_completed"

    # -----------------------------
    # LOSE CONDITIONS
    # -----------------------------
    LOST_TIMEOUT = "lost_timeout"

    # Persona explicitly rejected objective
    LOST_REJECTED = "lost_rejected"

    # Persona got angry / blocked user
    LOST_BLOCKED = "lost_blocked"

    # User violated challenge rules
    LOST_RULE_VIOLATION = "lost_rule_violation"

    # -----------------------------
    # OTHER STATES
    # -----------------------------
    ABANDONED = "abandoned"

    ACTIVE = "active"
```

---

## Values

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


#### Storyline Object
- `storyline` (string): The storyline
- `call_to_action` (string): The call to action

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
- Used for real-time messaging. Main events:
  - `join`: Register a user session (`{ user_id }`)
  - `send_message`: Send a chat message (`{ sender_id, receiver_id, text }`)
  - `receive_message`: Receive messages (including AI responses)
- See `app/socketio_server.py` for event logic.

---


## Notes
- All endpoints return JSON responses.
- CORS is enabled for all origins.
- For authentication and additional endpoints, refer to the backend source code.
