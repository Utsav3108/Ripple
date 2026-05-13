# API Documentation for WhatsApp Mobile App Backend

This document describes the main REST API endpoints for the WhatsApp mobile app backend, built with FastAPI.

## Base URL

    http://<server-address>/

---

## Endpoints

### 1. Root
- **GET /**
- **Description:** Health check endpoint.
- **Response:**
    - 200 OK: `{ "message": "FastAPI is running" }`

---

### 2. Search Presidents
- **GET /search-presidents/{query}**
- **Description:** Search for presidents by name or keyword.
- **Path Parameter:**
    - `query` (string): Search term
- **Response:**
    - 200 OK: List of President objects

#### President Object
- `id` (int)
- `name` (string)
- `desc` (string)
- `image_url` (string)

---

### 3. Get Presidents User Chatted With
- **GET /presidents/{user_id}**
- **Description:** Get a list of presidents a user has chatted with.
- **Path Parameter:**
    - `user_id` (int): User ID
- **Response:**
    - 200 OK: List of President objects (see above)

---

### 4. Get Messages Between Users
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

## WebSocket & Socket.IO
- **WebSocket endpoint:** `/socket.io`
- Used for real-time messaging (see implementation for details).

---

## Notes
- All endpoints return JSON responses.
- CORS is enabled for all origins.
- For authentication and additional endpoints, refer to the backend source code.
