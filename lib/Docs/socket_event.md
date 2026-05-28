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

---

## Challenge Events

### `join_challenge`
- **Description:** Joins a socket to a challenge room for group communication.
- **Payload:** `{ "challenge_session_id": int }`
- **Response:** None

### `complete_challenge`
- **Description:** Marks a challenge session as complete and leaves the challenge room.
- **Payload:**
    - `challenge_session_id`: int
    - `status`: str (completion status)
    - `reason`: str (optional, reason for completion)
- **Response:** None

---

## Messaging Events

### `send_message`
- **Description:** Sends a message from a user to a persona (or another user) within a challenge session. Triggers Gemini AI response in the background.
- **Payload:**
    - `sender_id`: int
    - `receiver_id`: int
    - `text`: str
    - `challenge_session_id`: int
    - `image_object_name`: str (optional)
- **Response:** None (AI response will be sent via `receive_message` event)

### `receive_message`
- **Description:** (Emitted by server) Delivers a message (AI or user) to all clients in the challenge room.
- **Payload:** Message object (see backend MessageResponse schema)

---

## Notes
- All events are asynchronous.
- Rooms are used for challenge sessions: `challenge:<challenge_session_id>`.
- The server may emit additional events for challenge status (e.g., timeout/loss) as needed.

---

For detailed payload schemas, refer to the backend Pydantic models in `app/schemas.py`.
