# Socket.IO Server Events Documentation

This document describes the Socket.IO events handled by the backend server in `socketio_server.py`. Use this as a reference for integrating with the mobile client.

---

## Connection Events

### `connect`
- **Description:** Triggered when a client connects to the Socket.IO server.
- **Payload:** None
- **Response:** None

### `disconnect`
- **Description:** Triggered when a client disconnects from the server.
- **Payload:** None
- **Response:** None

### `join`
- **Description:** Associates a socket session with a user ID.
- **Payload:** `{ "user_id": int }`
- **Response:** None

### `check_unblock_status`
- **Description:** On-demand poll for whether a persona session that was previously blocked (arousal threshold or repeated content violations) has since auto-unblocked. Reuses the same lazy unblock-on-load logic as a normal chat turn — no server-side timer/scheduler involved. If the session is still blocked, nothing is emitted.
- **Payload:** `{ "user_id": int, "persona_id": int }`
- **Response:** `persona_unblocked` emitted privately to the requesting client only (not broadcast to the room) if the persona is no longer blocked.

---

## Challenge Events


### `join_challenge`
- **Description:** Joins a socket to a challenge room for group communication. The server will add the socket to a room named `challenge:<challenge_session_id>`.
- **Payload:** `{ "challenge_session_id": int }`
- **Response:** None


### `challenge_completed`
- **Description:** (Emitted by server) Notifies all clients in a challenge room about the updated status of a challenge session (e.g., completed, failed, etc.).
- **Payload:**
  - `reason` (string, optional): Reason for challenge completion or status change
  - `challenge_status` (ChallengeResult): Status of the challenge (e.g., "COMPLETED", "FAILED", "ACTIVE")
  - `challenge_session_id` (int): The session ID for the challenge
  - `user_id` (int): The user who completed or is involved in the challenge
  - `challenge_id` (int): The challenge ID

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

## Messaging Events


### `send_message`
- **Description:** Sends a message from a user to a persona (or another user) within a challenge session. Triggers Gemini AI response in the background. The server will also update message history and cache.
- **Payload:**
  - `sender_id`: int
  - `receiver_id`: int
  - `text`: str
  - `challenge_session_id`: int
  - `image_object_name`: str (optional)
- **Response:** None (AI response will be sent via `receive_message` event)


### `receive_message`
- **Description:** (Emitted by server) Delivers a message (AI or user) to all clients in the challenge room.
- **Payload:**
  - `id` (int): Message ID
  - `sender_id` (int): Sender user ID
  - `receiver_id` (int): Receiver user ID
  - `text` (string): Message text
  - `image_object_name` (string, optional): Name of the image object if present
  - `challenge_session_id` (int, optional): Challenge session ID if message is part of a challenge
  - `persona_session_id` (int, optional): The persona session this message belongs to (regular chat only, `null` for challenges). Server-assigned — clients never set this on `send_message`, only read it here to track the active session for a given (persona, user) pair.


### `persona_blocked`
- **Description:** (Emitted by server) Fires on the exact turn a persona session transitions into the blocked state (arousal threshold or repeated content violations) — not on subsequent turns while already blocked. Emitted to the same room as, and alongside, that turn's `receive_message` (the in-character canned refusal) — these are two independent signals, not a replacement for one another.
- **Payload:**
  - `persona_session_id` (int): The persona session that just became blocked
  - `block_reason` (string): `"arousal_threshold"` or `"repeated_content_violations"`
  - `blocked_until` (string, ISO 8601): When the block auto-expires

### `persona_unblocked`
- **Description:** (Emitted by server, private) Notifies a single requesting client, in response to `check_unblock_status`, that a persona session is no longer blocked. Never broadcast to the room.
- **Payload:**
  - `persona_session_id` (int): The persona session that is now unblocked


---



## Notes
- All events are asynchronous.
- Rooms are used for challenge sessions: `challenge:<challenge_session_id>`.
- The server may emit additional events for challenge status (e.g., timeout/loss) as needed.
- The server manages user-to-socket mapping and message caching for performance.
- All event payloads are fully described above for mobile integration.
